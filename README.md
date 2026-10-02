<p align="center">
  <img src="docs/readme/hero.png" width="100%" alt="RecOn. Deciding together, minus the group chat.">
</p>

<p align="center">
  <b>An iOS app for making group decisions.</b><br>
  Swipe through the options, make your pick, and get a winner.<br>
  <sub>By Anatoli Monsalve and Ethan Chen</sub>
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

## How it works

Pick a topic, swipe through the options, then submit one final pick. The option
with the most likes wins. Ties are settled by a draw between the tied options,
weighted by how many people made each one their final pick, so chance only
decides when the vote genuinely cannot.

Solo mode is the same rule with one voter: swipe, and it draws from what you
liked. Parties are invite-only. The host shares a code and you enter it on the
home screen.

## Running it

Set up the backend first, which needs Postgres, a virtualenv, migrations and
secrets: [`recon_backend/README.md`](recon_backend/README.md). Debug builds of
the app expect it on port 5001.

```bash
cd recon_backend
FLASK_APP=wsgi:app ./venv/bin/flask run --port 5001
```

Then open `recon_frontend/recon.xcodeproj` and run. The API URL is a build
setting in `recon_frontend/Config/`, not a constant in the source, and the
release one stays a placeholder until DNS and TLS are live.

## How it is built

```
recon_frontend/   SwiftUI app
recon_backend/    Flask API, Postgres, migrations
docs/             measurements, image credits, README art
```

The app holds no decision logic. It renders what the server sends and calls
`/v1`, and never counts votes or reaches a third party on its own.

- **Auth.** Tokens live in the Keychain. Access tokens are short-lived and
  refresh tokens rotate, so the client stores both halves of every refresh.
- **Places.** The phone sends coordinates, the server queries Overpass behind a
  Postgres cache, and no provider key ever ships in the app. Option artwork is
  fetched at runtime, never bundled ([credits](docs/credits.md)).
- **Performance.** The results endpoint went from 7 queries per request to 4 by
  folding three aggregates and a lazy member load into one statement. Worth
  +14% throughput and −17% p50 under load, and nothing at all at concurrency 1,
  which is the interesting part ([numbers](docs/measurements.md)).

---

<p align="center"><sub>This is a fresh repo. We had to start over because of too many merge conflicts when trying to combine the parts we built separately.</sub></p>
