<p align="center">
  <img src="docs/readme/hero.png" width="100%" alt="RecOn. Deciding together, minus the group chat.">
</p>

<p align="center">
  <b>An iOS app for making group decisions.</b><br>
  Swipe through the options, make your pick, and get a winner.<br>
  <sub>By Anatoli Monsalve and Ethan Chen</sub>
</p>

<p align="center">
  <a href="#how-it-works">How it works</a> &nbsp;&bull;&nbsp;
  <a href="#what-we-built">What we built</a> &nbsp;&bull;&nbsp;
  <a href="#run-it">Run it</a> &nbsp;&bull;&nbsp;
  <a href="docs/measurements.md">Measurements</a> &nbsp;&bull;&nbsp;
  <a href="https://www.youtube.com/watch?v=55O7b-9GzwY">Demo video</a>
</p>

<p align="center">
  <a href="https://www.youtube.com/watch?v=55O7b-9GzwY"><img src="docs/readme/demo.png" width="240" alt="Watch the demo on YouTube"></a>
</p>

<p align="center">
  <img src="docs/readme/screens.png" width="100%" alt="Five screens. Decide together: the welcome screen. What's it gonna be? Home, with the topics and a dinner party waiting on your swipes. Swipe right for yes: a restaurant in the swipe deck. One pick each: choosing your final pick. We have a winner: the party's result.">
</p>

<p align="center">
  <img src="docs/readme/info.png" width="100%" alt="Platform: iOS 26 and SwiftUI. Backend: Flask and PostgreSQL 16. Three topics: food, study spots and movies. Under load: 14% more throughput on the results endpoint. Made by Anatoli and Ethan.">
</p>

---

## How it works

Pick a topic, everyone swipes, and the server picks the winner.

The winner is whatever the most people liked. Everyone also submits one final
pick, and ties get drawn with those picks as weights. Something four people
chose beats something nobody chose, even when the likes come out even.

Solo mode is the same rule with one voter. To join a party you need a code from
whoever started it.

## What we built

```
recon_frontend/   SwiftUI app
recon_backend/    Flask API, Postgres, migrations
docs/             measurements, credits, README art
```

Why everything moved to the server, and the security holes we closed on the
way, are in [BACKEND_SPEC.md](BACKEND_SPEC.md).

Nothing that decides anything runs on the phone. The app draws screens and
calls the API. Our first version counted votes in Swift and queried Overpass
straight from the device, and moving all of that to the server was most of the
rewrite.

- **Approval voting, server side.** One verdict per person per option, enforced
  by the primary key. Ties break by lottery weighted on final picks.
- **Tokens in the Keychain.** Short-lived access tokens, refresh tokens that
  rotate on every use, reuse detection on the server.
- **No third-party keys on the device.** Venue lookups go through our API and
  cache in Postgres for a day.
- **7 queries per request down to 4.** Three aggregates and a lazy load folded
  into one statement: +14% throughput and -17% p50 under load. One request at a
  time it changed nothing. [How we measured](docs/measurements.md)

## Run it

Needs Xcode 26 and Postgres 16, or Docker for the database. First-time setup
(the virtualenv and the `.env` secrets) is in
[recon_backend/README.md](recon_backend/README.md). Debug builds look for the
API on port 5001, because macOS AirPlay takes 5000.

```bash
cd recon_backend
docker compose up -d db                  # or a local Postgres 16
FLASK_APP=wsgi:app ./venv/bin/flask db upgrade
FLASK_APP=wsgi:app ./venv/bin/flask run --port 5001
```

Then open `recon_frontend/recon.xcodeproj` and run.

The backend tests cover auth, parties, invites, swipes and picks, and run
against a separate `recon_test` database (the backend README sets it up):

```bash
cd recon_backend && ./venv/bin/pytest
```
