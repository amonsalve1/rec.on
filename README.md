# RecOn

Anatoli Monsalve and Ethan Chen

DEMO: https://www.youtube.com/watch?v=55O7b-9GzwY

iOS app for making group decisions. Swipe through options, pick favorites, and get a winner.

Note: This is a fresh repo. We had to start over because of too many merge conflicts when trying to combine the parts we built separately.

## What it does

RecOn helps you and your friends decide where to eat, where to study, or what movie to watch. You can use it solo or with a group.

In party mode, everyone swipes through options and picks their favorite. The server counts approvals across the group and the most-approved option wins, with ties broken by a lottery weighted by final picks.

In solo mode, you swipe through options yourself and the server draws a winner from the ones you liked.

## Setup

### Requirements

- Xcode 15 or later
- iOS 17.0+
- Swift 5.9+
  
### Backend

The app connects to the Flask backend in `recon_backend/` (setup in its README). The API base URL comes from the build configuration — `recon_frontend/Config/Debug.xcconfig` points at a local server, `Release.xcconfig` at the deployed domain.

## Features

- Sign up and sign in
- Solo decision mode
- Party decision mode with invite links
- Location-based restaurant search
- Swipe interface for browsing options
- Random winner selection
- Recent picks history
- User profiles

## Notes

The app uses UserDefaults for local storage of auth tokens and user preferences. Location services are used for finding nearby restaurants when the topic is "food nearby".

For party mode, one person creates a session and shares an invite link. Others join using the link or session ID.
