# Measurements

All numbers captured 2026-07-30 on a MacBook Pro (Apple silicon), local
Postgres 16, gunicorn `-w 2 --threads 4`, bench database seeded by
`recon_backend/scripts/seed_bench.py` (200 parties × 10 members × 15 options
= **30,000 swipe rows**, 2,000 final picks). Load generator: ApacheBench,
`ab -n 1000 -c 50`. Rate limiting was off for the runs
(`RATELIMIT_ENABLED=false`, which exists for this). Our first run was useless
because 761 of 1000 requests hit the default `120/minute` limit and came back
429.

Target endpoint: `GET /v1/parties/<id>/results` (the approval-aggregation
read), authorized as a member of a fully-voted 10×15 party.

## Endpoint latency, before → after

`ab -n 1000 -c 50 -H "Authorization: Bearer …" http://127.0.0.1:5001/v1/parties/<id>/results`

| | before | after | change |
|---|---|---|---|
| p50 | 73 ms | 59 ms | −19% |
| p95 | 147 ms | 131 ms | −11% |
| p99 | 151 ms | 142 ms | −6% |
| throughput | 591 req/s | 722 req/s | +22% |
| failed | 0 | 0 | |

"After" = collapsing the endpoint's three aggregate queries plus a lazy
`party.members` relationship load into **one** SQL statement (options
LEFT JOINed to approval and pick aggregates, electorate as a subquery).
Request-scoped query count fell from 7 to 4 (the other 3 are auth + party
scoping). At `-c 50` against 8 server threads, most of the wall-clock p50 is
queueing; the per-request in-process time is ~8 ms (see profile), which is
why a 3-query cut moves throughput 22% but not 3×.

### Re-measured 2026-08-02

Repeated on a freshly seeded bench database after the party-list and
nearby-preview endpoints landed. `app/api/picks.py` itself is unchanged
since the optimization above, so this is a regression check, not a new
result. The extra routes and blueprints cost the endpoint nothing.

Three consecutive runs, same command:

| run | p50 | p95 | p99 | throughput |
|---|---|---|---|---|
| 1 | 60 ms | 113 ms | 135 ms | 755 req/s |
| 2 | 64 ms | 114 ms | 125 ms | 783 req/s |
| 3 | 57 ms | 74 ms | 79 ms | 857 req/s |

Run-to-run spread is wider than the improvement being claimed at the tail
(p95 varies 74–114 ms across identical runs on an unloaded laptop), so take
the −11% p95 above with salt. p50 and throughput are the stable signals, and
both hold. Nothing regressed.

Profile at the same time: **5.7 ms/request in-process, 4.0 queries/request,
49% of time in `psycopg` wait.** The query-count cut is still in place, and
waiting on round trips is still the main cost.

### A/B re-run, 6 alternating reps (2026-08-02)

The numbers at the top of this file were a single before run against a single
after run, which the run-to-run spread above says is not enough. Redone as an
alternating A/B: both versions of `results()` are replayed out of git
(`HEAD` and `71309b3^`), swapped into place one rep at a time, so machine
drift lands on both halves equally. Each rep measures twice: `-c 1` for the
per-request service time and `-c 50` for saturated throughput.

| median of 6 | before | after | change |
|---|---|---|---|
| serial latency (`-c 1`) | 6.8 ms | 6.7 ms | −0.8% (noise) |
| throughput (`-c 50`) | 529 req/s | 605 req/s | **+14.4%** |
| p50 (`-c 50`) | 93 ms | 77 ms | **−17.2%** |
| p95 (`-c 50`) | 132.5 ms | 118.5 ms | −10.6% |

After won throughput in 6 reps out of 6, so the direction is real even though
the machine was busier than it was for the original run (which is why both
columns are slower in absolute terms than the table at the top).

The interesting line is the first one: **at concurrency 1 the two versions are
the same speed.** Three fewer round trips buy nothing when nobody is queued
behind you. The win only shows up under load, where holding a pooled
connection for 7 queries instead of 4 is what actually costs. So the claim is
"+14% throughput and −17% p50 under load", not "the endpoint is faster".

One trap worth writing down: the first attempt at this compared the endpoint
against *itself*. The script snapshotted "after" from the working tree, and a
previous aborted run had left the tree holding the before version. Six reps of
a dead heat is what tipped it off. The script now pulls both versions from git
every run and restores the tree at the end.

## Query plans (`EXPLAIN ANALYZE`)

**Approval aggregate, before any change.** The planner uses the existing
`ix_swipes_party_user` composite index; nested loop over the 10 active
members:

```
Index Scan using ix_swipes_party_user on swipes (actual time=0.006..0.010 rows=5 loops=10)
  Index Cond: ((party_id = 101) AND (user_id = party_members.user_id))
  Filter: (liked IS TRUE)  Rows Removed by Filter: 10
Execution Time: 0.398 ms
```

**Negative result, kept deliberately:** the planned partial index
`ix_swipes_party_liked ON swipes (party_id, option_id) WHERE liked` was
created and measured, and the planner never chose it (plan unchanged; 0.215
ms vs 0.398 ms is cache warmth, not the index). At party scale (~150 swipe rows
per party) the composite PK/index already covers the access path. **We
dropped the index and no migration ships.** An index the planner ignores is
just extra work on every write.

**Combined single query (the shipped optimization):**

```
Execution Time: 0.493 ms   (one statement replacing three at ~0.4 ms each + members load)
Execution Time: 0.506 ms   (re-measured 2026-08-02, fresh bench database)
```

Planning time for this statement is ~2.9 ms on a cold plan cache, roughly
six times its execution time. At this data size the work is in getting to
the database, not in the query.

## Python profile (`cProfile`, 50 requests through the test client)

```
50 requests in 0.404 s  →  ~8 ms/request in-process
350 session.execute calls (7 queries/request, before optimization)
psycopg connection.wait: 0.224 s  →  55% of total time is DB round-trip wait
```

The hot spot was never computation, it was round trips. That's why we
rewrote it as a single query (7 → 4 per request) rather than any
micro-optimization of the aggregation itself.

## Venue lookup: cold vs warm (provider cache)

`POST /v1/parties` with the same rounded coordinates, sequential calls:

| call | time | what happened |
|---|---|---|
| 1 | 20.73 s | Overpass timed out → seed fallback (provider `seed`), nothing cached |
| 2 | 8.37 s | live Overpass answered, payload cached (provider `overpass`) |
| 3 | **0.017 s** | cache hit (provider `overpass`) |

Warm-cache party creation is **~490× faster** than a live Overpass round
trip, and the cache also absorbs Overpass's worst-case behavior (call 1's
20 s timeout), which is exactly why the lookup is proxied server-side.
Cache TTL is 24 h, keyed on coordinates pre-rounded to 3 decimal places.

## Reproduce

```bash
# throwaway database
psql -h localhost -d postgres -c "CREATE DATABASE recon_bench OWNER recon"

cd recon_backend
export DATABASE_URL=postgresql+psycopg://recon:recon@localhost:5432/recon_bench \
       JWT_SECRET_KEY=bench-only SERVER_PEPPER=bench-pepper RATELIMIT_ENABLED=false
python scripts/seed_bench.py            # prints party id + bearer token
gunicorn -w 2 --threads 4 -b 127.0.0.1:5001 wsgi:app &
ab -n 1000 -c 50 -H "Authorization: Bearer <token>" \
   http://127.0.0.1:5001/v1/parties/<party>/results
```

For the A/B re-run, one rep is:

```bash
git show 71309b3^:recon_backend/app/api/picks.py > /tmp/before.py   # 7 queries
git show HEAD:recon_backend/app/api/picks.py     > /tmp/after.py    # 4 queries
cp /tmp/before.py recon_backend/app/api/picks.py                    # (then /tmp/after.py)
# restart gunicorn, wait for /v1/health, then both of:
ab -n 300  -c 1  -H "Authorization: Bearer <token>" "$URL"   # service time
ab -n 1000 -c 50 -H "Authorization: Bearer <token>" "$URL"   # under load
git checkout -- recon_backend/app/api/picks.py
```

Alternate before/after per rep and take medians. Pull both versions from git,
never from the working tree: a half-finished run leaves the tree holding the
wrong one.
