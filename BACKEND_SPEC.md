# How the backend works, and why

## The split

The server owns the data, the rules and every call to a third party. The
Swift app draws state and calls `/v1`. Our first version did it the other way
round: the backend was never finished, so vote counting and venue lookups
ended up in the client. Moving them to the server is most of what this repo
is.

## Security

| Problem | What we did |
|---|---|
| The app talked plain HTTP to a raw IP address | Release builds are HTTPS-only, with the base URL set per build configuration (the production domain isn't live yet) |
| Auth tokens sat in `UserDefaults` | Moved to the Keychain, with a one-time migration at launch |
| Venue lookups ran on the device | Proxied through the server |

The venue proxy is the best argument for having a backend at all. Any
provider key stays on the server, and lookups can be cached in Postgres for
everyone instead of repeated on every phone.

## Picking a winner

The first mechanic drew at random from everyone's favorite. That throws away
every swipe and treats one pick per person as the whole signal. We looked at
three real voting rules:

- **Approval voting:** each option is approved or not, and the most approvals
  wins.
- **Borda count:** points by rank position, summed across voters.
- **Condorcet:** the option that beats every other one head to head, if there
  is one.

We went with **approval voting, with ties broken by a lottery weighted on
final picks.** The swipe deck already gives us exactly one yes or no per
person per option, so approval voting uses everything the app collects
without making anyone rank anything. Borda would need a ranking screen, which
makes the app slower at the one thing it's for. Condorcet can end with no
winner, and a group trying to pick dinner needs one. The weighted lottery
keeps a moment of chance at the end without letting chance beat a real
majority.

The rule also has to survive real groups:

- **Two people voting at once.** Swipes are keyed on
  `(party_id, option_id, user_id)`, so swiping again updates the old answer
  instead of adding a second one. Spinning is idempotent: once a party has a
  winner, spinning again returns the same one.
- **Someone joining halfway.** Not allowed. You can only join in the lobby,
  so the number of voters is fixed and "3 of 4 have voted" is always true.
- **Someone disappearing.** Leaving removes you from the vote and from the
  count the spin waits on, and a sweeper closes parties whose deadline has
  passed, so one dead phone can't hold a vote open forever.

## Polling, not WebSockets

A party changes at the speed people swipe, not in milliseconds. Every
change bumps a version number that doubles as an ETag, so a poll that finds
nothing new is a cheap 304. WebSockets would add infrastructure for no gain
we could measure, so the app polls.

## Measuring

Every optimization is measured before and after, with the exact commands, in
[docs/measurements.md](docs/measurements.md): endpoint latency under load
with `ab`, query plans with `EXPLAIN ANALYZE`, venue lookups cold and warm,
and `cProfile` on the vote-counting path.
