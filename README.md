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

## What it does

RecOn helps you and your friends decide where to eat, where to study, or what movie to watch. Use it solo or with a group.

**Party mode.** Everyone swipes through the options, then submits one final pick. The server counts approvals across the group and the most-approved option wins. A tie at the top goes to a lottery weighted by how many final picks each tied option got, so the random draw only ever settles a genuine tie.

**Solo mode.** Same endpoint, same rule, with an electorate of one: you swipe, and the server draws a winner from the options you liked.

## Features

- **Solo or party.** Decide on your own, or create a party and share its invite code.
- **Three topics.** Food nearby, study spots and movies.
- **Swipe deck.** Right for yes, left for no.
- **A fair winner.** Approval voting, with a pick-weighted lottery that only breaks ties.
- **Restaurants near you,** looked up by the server rather than the phone.
- **Pick up where you left off.** Resume a party from the home screen, or swipe its row to leave.
- **Accounts.** Sign up, sign in, a profile, and your recent picks.

## How it fits together

    recon_frontend/   SwiftUI app
    recon_backend/    Flask API, Postgres, migrations
    docs/             measurements, image credits, README art

All of the decision logic lives in the backend. The app renders state and calls `/v1`. It does not count votes, choose winners, or call any outside service on its own; beyond the API, the only thing it loads is option artwork, from URLs the server hands it.

## Under the hood

**Tokens live in the Keychain** ([`TokenStore.swift`](recon_frontend/recon/Services/TokenStore.swift)). Access tokens are short-lived and refresh tokens rotate, so the client has to store both halves of every refresh response. Non-secret preferences like display name and recent picks are still in UserDefaults.

**Joining is invite-only.** The host mints a code and the only place to enter one is the join sheet on the home screen. There are no invite links or deep links, a party ID on its own will not get you in, and non-members get a 404 instead of a 403 so party IDs cannot be probed.

**Location is only for food nearby.** The device sends coordinates and the server does the lookup through Overpass, backed by a Postgres cache with a seed fallback, so no places provider is ever called from the phone. Movies and study spots come from a catalogue and never needed location.

**Artwork is never bundled.** It is fetched at runtime from the image an option's OpenStreetMap or Wikidata entry links to. Options without one get a lettered card, which is the designed default rather than a missing image. Sources and licences are in [`docs/credits.md`](docs/credits.md).

**Fewer round trips, measured.** The results endpoint went from 7 queries per request to 4 by folding three aggregate queries and a lazy member load into one statement. In an alternating A/B, median of 6 runs, that is worth +14% throughput and −17% p50 at 50 concurrent requests. At concurrency 1 the two versions are the same speed, so the win only shows up under load. Commands, query plans and caveats are in [`docs/measurements.md`](docs/measurements.md).

## Running it

Start the backend first. Full setup (Postgres, virtualenv, migrations, secrets) is in [`recon_backend/README.md`](recon_backend/README.md).

Debug builds of the app expect the API on port 5001, so run it there:

```bash
cd recon_backend
FLASK_APP=wsgi:app ./venv/bin/flask run --port 5001
```

Then open `recon_frontend/recon.xcodeproj` and run on a simulator.

The base URL is a build setting, not a constant in source. `recon_frontend/Config/Debug.xcconfig` points at localhost; `Release.xcconfig` points at the deployed domain and is still a placeholder until DNS and TLS are live (see [`recon_backend/deploy/README.md`](recon_backend/deploy/README.md)).

### Requirements

- Xcode 26 or later
- iOS 26.0+
- Swift 5 language mode
- Postgres 16

---

<p align="center"><sub>This is a fresh repo. We had to start over because of too many merge conflicts when trying to combine the parts we built separately.</sub></p>
