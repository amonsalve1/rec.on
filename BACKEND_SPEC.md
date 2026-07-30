# RecOn Backend — Spec

## Why this project exists

The Flask backend was never finished, so API logic and business rules ended up
in the Swift client. This project moves the boundary back to where it belongs:
the server owns the data, the rules, and every third-party call, and the client
renders state.

## Security issues to fix first

| Issue | Where | Fix |
|---|---|---|
| Plain HTTP to a raw IP | `APIConfig.swift` — `http://34.21.78.117` | HTTPS, domain name, base URL from build config |
| Auth tokens in `UserDefaults` | Client | Move to Keychain |
| Third-party lookups from the device | Places/venue lookup | Proxy through the server |

Proxying the places lookup is the strongest argument for the backend existing
at all: it keeps any future provider key server-side and makes caching possible.

## Build order

Each step leaves the app in a working state.

1. **Auth** — bcrypt password hashing, short-lived access tokens, rotating
   refresh tokens with reuse detection
2. **Party sessions** — create, join by invite code, state stored server-side
3. **Vote aggregation** — a real preference-aggregation rule, computed on the
   server
4. **Places proxy** — server-side provider calls with a Postgres cache and a
   seed fallback
5. **Deploy** — behind a domain with TLS

Polling first; WebSockets only if polling demonstrably fails. Party state
changes are low-frequency and a version counter with ETags makes each poll
cheap, so the added infrastructure is not justified yet.

## Vote aggregation

Random selection from everyone's favorites is a weak mechanic — it ignores
every swipe and treats one arbitrary pick per person as the whole signal. The
options considered:

- **Approval voting** — each option is approved or not; highest approval count
  wins
- **Borda count** — points by rank position, summed across voters
- **Condorcet** — the option that beats every other head-to-head, if one exists

**Decision: approval voting, with a final-pick-weighted lottery to break ties.**
The swipe deck already produces exactly one approve/reject verdict per member
per option, so approval voting uses the full set of signals the app collects
without asking anyone to rank anything. Borda would need a ranking UI that
does not exist and that lengthens the interaction the app is built to shorten.
Condorcet can produce no winner at all, which is unacceptable for a group that
needs to pick dinner. Ties go to a lottery weighted by final picks, so the
mechanic keeps a moment of chance without letting chance override consensus.

State questions the rule has to answer:

- **Simultaneous votes** — the swipes table is keyed on
  `(party_id, option_id, user_id)`, so a re-swipe updates rather than
  duplicates, and the spin is idempotent: once a winner exists, later spins
  return the same party.
- **Joining mid-session** — not allowed. Joining is lobby-only, which fixes the
  denominator and makes "3 of 4 have voted" a true statement.
- **A client that drops out** — leaving removes the member from both the
  electorate and the spin gate, and an expiry sweeper closes parties whose
  deadline passes, so one vanished client cannot wedge a vote open forever.

## Conventions

- Commit after each logical unit of work; one concern per commit
- Commit messages in imperative mood: "Add session join endpoint"
- No secrets in source; everything from environment config
- Tests pass before any commit to main

## Measurements

Captured before optimizing as well as after — both halves of the number are
recorded in `docs/measurements.md`.

| Metric | How |
|---|---|
| Endpoint p50/p95/p99 | `ab -n 1000 -c 50 http://localhost:5001/v1/...` |
| Query execution time | `EXPLAIN ANALYZE` before and after an index change |
| Cache effect | Venue lookup latency, cold vs warm |
| Python hot spots | `cProfile` on the aggregation path |
