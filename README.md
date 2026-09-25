# Park It

(Code name **DockNearby** — targets, bundle IDs, and the repo keep that name.)

A SwiftUI app + widgets (home screen and Lock Screen) that show open Citi Bike docks —
or bikes — near you, near a destination, or at your favorite stations.

- **Widgets** — home screen (small / medium / large) and Lock Screen (rectangular / circular /
  inline), with a ↻ refresh button on the larger ones. Each can show *Closest to me*,
  *My favorites*, *Near a destination*, or *Commute* — near Work 4am–noon, Home otherwise,
  once both are set (long-press → Customize → tap the widget).
  Each widget also picks what to **Count**: open docks, any bike, e-bikes, or classic bikes.
  Rectangular shows up to three dots — the count inside, short street name below
  ("W 72 St & Amsterdam Ave" → "72nd") — under a "↻ 5 min ago" row: tap it to refresh
  (an interactive `AppIntent` button; runs once the phone is unlocked).
- **App**: asks for location on first launch (which also unlocks location for the widget).
  The main screen is a full-screen map (pins show open docks) under a draggable sheet
  with search, chips, and the nearby list; tap a pin or row for live counts, a favorite
  button, and cycling directions. A **Park | Ride** switch flips everything between open docks
  and available bikes (with *E-bikes* / *Classic* chips in Ride); the hide-empty chip hides
  stations with none. Home, Work,
  and other saved places appear as chips and show docks near there — in the app and as a widget mode.
- **Siri / Shortcuts**: "How many docks at *station* in Park It",
  "Docks near *destination* in Park It".

Data: Citi Bike's public [GBFS 1.1 feed](https://gbfs.lyft.com/gbfs/1.1/bkn/gbfs.json) — no API key.

## Layout

| Path | What |
| --- | --- |
| `project.yml` | XcodeGen spec — **source of truth** for the Xcode project |
| `BikeKit/` | Local Swift package: GBFS models, `GBFSClient`, `SharedStore` (App Group) |
| `DockNearby/` | iOS app: onboarding, map (`HomeView`) + draggable sheet (`StationsSheet`), shared `HomeModel` |
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
   Set these in `project.yml`, not in Xcode's Signing tab — `xcodegen generate` rebuilds
   the project and wipes anything set there.
2. `xcodegen generate`, open the project, pick your phone, Run.
   Automatic signing registers the App IDs and App Group for you.
3. Allow location, star a few stations, then add the widget to your Lock Screen.

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
- Widgets reload about every 15 minutes at best (iOS rations reloads); the ↻ button forces one.
- No location in the widget? Check the app has permission. The widget falls back to the last
  location the app saw, then to 71st & Amsterdam.
- Widget extensions have a ~30 MB memory limit; BikeKit caches only the station fields it uses.

## Ideas

Ride Live Activity
