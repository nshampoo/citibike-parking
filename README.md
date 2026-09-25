# DockNearby

A SwiftUI app + home screen widget that shows open Citi Bike docks near you,
with classic/e-bike counts and a tap-to-refresh button.

- **Widget** (home screen: medium / large; Lock Screen: rectangular / circular / inline): each widget can show *Closest to me* or *My favorites*
  (long-press → Edit Widget). Refresh button is an interactive `AppIntent` (iOS 17+).
  The Lock Screen rectangular widget shows up to three dots — open docks inside, short
  street name below ("W 72 St & Amsterdam Ave" → "72nd").
- **App**: asks for location on first launch (which also unlocks location for the widget).
  The main screen is a map of stations (pins show open docks) above a nearby list;
  tap a pin or row for live counts, a favorite button, and cycling directions.
  A filter hides full stations. **Destinations** (Work, Home…)
  show docks near a place before you get there — in the app and as a widget mode.
- **Siri / Shortcuts**: "How many docks at *station* in DockNearby",
  "Docks near *destination* in DockNearby".

Data: Citi Bike's public [GBFS 1.1 feed](https://gbfs.lyft.com/gbfs/1.1/bkn/gbfs.json) — no API key.

## Layout

| Path | What |
| --- | --- |
| `project.yml` | XcodeGen spec — **source of truth** for the Xcode project |
| `BikeKit/` | Local Swift package: GBFS models, `GBFSClient`, `SharedStore` (App Group) |
| `DockNearby/` | iOS app: onboarding, map + nearby list, station sheet, favorites |
| `DockWidget/` | Widget extension: timeline provider, intents, views, `LocationFetcher` |
| `Shared/` | Source compiled into both app and widget (`DestinationEntity`) |

The `.xcodeproj`, Info.plists and entitlements are **generated** and gitignored.
Change `project.yml`, not Xcode's project settings UI.

## Setup

```sh
brew install xcodegen
xcodegen generate
open DockNearby.xcodeproj
```

## Running on your iPhone

1. In `project.yml`, set the three values at the top:
   - `DEVELOPMENT_TEAM` — your Team ID (Xcode → Settings → Accounts, or developer.apple.com → Membership)
   - `BASE_BUNDLE_ID` — e.g. `com.yourname.docknearby` (widget becomes `<that>.DockWidget`)
   - `APP_GROUP_ID` — e.g. `group.com.yourname.docknearby`
2. `xcodegen generate`, open the project, pick your phone, Run.
   Automatic signing registers the App IDs and App Group for you.
3. Allow location, star a few stations, then add the widget from the home screen.

## Commands

```sh
# Build for the simulator
xcodebuild -project DockNearby.xcodeproj -scheme DockNearby \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# BikeKit unit tests (offline)
cd BikeKit && swift test

# Include a test against the live Citi Bike feed
cd BikeKit && LIVE_GBFS=1 swift test
```

## Gotchas

- **iCloud Drive + codesign:** this repo lives in an iCloud-synced folder. Keep build output in
  the default `~/Library/Developer/Xcode/DerivedData` — building *inside* the repo fails with
  "resource fork, Finder information, or similar detritus not allowed".
- Widgets reload about every 15 minutes at best; button taps get extra budget.
- No location in the widget? Check the app has permission. The widget falls back to the last
  location the app saw, then to 71st & Amsterdam.
- Widget extensions have a ~30 MB memory limit; BikeKit caches only the station fields it uses.

## Ideas

Ride Live Activity
