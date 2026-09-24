# RecOn

Anatoli Monsalve and Ethan Chen

DEMO: https://www.youtube.com/watch?v=55O7b-9GzwY

iOS app for making group decisions. Swipe through options, pick favorites, and get a winner.

Note: This is a fresh repo. We had to start over because of too many merge conflicts when trying to combine the parts we built separately.

## What it does

RecOn helps you and your friends decide where to eat, where to study, or what movie to watch. You can use it solo or with a group.

In party mode, everyone swipes through the options and then submits one final pick. The server counts approvals across the group and the most-approved option wins. If there is a tie at the top, it goes to a lottery weighted by how many final picks each tied option got, so the random draw only ever settles a genuine tie.

Solo mode runs on the same endpoint and the same rule with an electorate of one: you swipe, and the server draws a winner from the options you liked.

## Layout

    recon_frontend/   SwiftUI app
    recon_backend/    Flask API, Postgres, migrations
    docs/             measurements, image credits

All of the decision logic lives in the backend. The app renders state and calls `/v1`. It does not count votes, choose winners, or talk to any outside service on its own.

## Running it

Start the backend first. Full setup (Postgres, virtualenv, migrations, secrets) is in `recon_backend/README.md`.

Debug builds of the app expect the API on port 5001, so run it there:

    cd recon_backend
    FLASK_APP=wsgi:app ./venv/bin/flask run --port 5001

Then open `recon_frontend/recon.xcodeproj` and run on a simulator.

The base URL is a build setting, not a constant in source. `recon_frontend/Config/Debug.xcconfig` points at localhost; `Release.xcconfig` points at the deployed domain and is still a placeholder until DNS and TLS are live (see `recon_backend/deploy/README.md`).

### Requirements

- Xcode 15 or later
- iOS 17.0+
- Swift 5.9+
- Postgres 16

## Features

- Sign up and sign in
- Solo decision mode
- Party mode: create a party, share the invite code, everyone swipes and picks
- Nearby restaurants for the "food nearby" topic, looked up server-side
- Swipe deck for browsing options
- Approval-voted winner with a pick-weighted tiebreak
- Resume an in-progress party from the home screen, or swipe its row to leave
- Recent picks history
- User profiles

## Notes

Auth tokens live in the Keychain (`recon_frontend/recon/Services/TokenStore.swift`). Access tokens are short-lived and refresh tokens rotate, so the client has to store both halves of every refresh response. Non-secret preferences like display name and recent picks are still in UserDefaults.

Joining is invite-only. The host mints a code and the only place to enter one is the join sheet on the home screen. There are no invite links or deep links, a party ID on its own will not get you in, and non-members get a 404 instead of a 403 so party IDs cannot be probed.

Location is only used for the "food nearby" topic. The device sends coordinates and the server does the lookup through Overpass, backed by a Postgres cache with a seed fallback, so no places provider is ever called from the phone. Movies and study spots come from a catalogue and never needed location.

Option artwork is fetched at runtime from Wikimedia and is not bundled with the app. Options without a picture get a lettered card, which is the designed default rather than a missing image. See `docs/credits.md`.

Before and after numbers for the results endpoint, with the exact commands used, are in `docs/measurements.md`.
