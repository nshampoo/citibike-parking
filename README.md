# Park It

(Code name **DockNearby** — targets, bundle IDs, and the repo keep that name.)

A SwiftUI app + widgets that show open Citi Bike docks — or bikes — near you, near a place
you're heading, or at your favorite stations.

- **App**: a full-screen map (pins show open docks, or bikes) under a draggable sheet with
  search, two chip rows, and the nearby list. Tap a pin or row for live counts, Favorite, and
  cycling directions.
  - Row 1: **Park | Ride** flips everything between open docks and available bikes
    (*E-bikes* / *Classic* narrow it in Ride); the hide-empty chip hides stations with none.
  - Row 2: **Home**, **Work**, and other saved places. Tap one to see stations there.
  - Asks for location on first launch (which also unlocks location for the widgets). Outside
    Citi Bike's service area it shows New York instead of empty distances.
- **Widgets** — home screen (small / medium / large) and Lock Screen (rectangular / circular /
  inline). Each can show *Closest to me*, *My favorites*, *Near a destination*, or *Commute*
  (near Work 4am–noon, Home otherwise, once both are set), and **Count** parking, any bike,
  e-bikes, or classic bikes. Larger sizes have a ↻ refresh button (an interactive `AppIntent`;
  on the Lock Screen it runs once the phone is unlocked). Rectangular shows up to three dots —
  the count inside, short street name below ("W 72 St & Amsterdam Ave" → "72nd").
- **Station widget** (home screen small / medium, Lock Screen rectangular / circular / inline):
  the full rundown of one station — parking, classic bikes, e-bikes — defaulting to your
  nearest favorite.
- **Siri / Shortcuts**: "How many docks at *station* in Park It",
  "Docks near *destination* in Park It".

Data: Citi Bike's public [GBFS 1.1 feed](https://gbfs.lyft.com/gbfs/1.1/bkn/gbfs.json) — no API key.

## Layout

| Path | What |
| --- | --- |
| `project.yml` | XcodeGen spec — **source of truth** for the Xcode project |
| `BikeKit/` | Local Swift package: GBFS models, `GBFSClient`, `SharedStore` (App Group) |
| `DockNearby/` | iOS app: onboarding, map (`HomeView`) + draggable sheet (`StationsSheet`), shared `HomeModel` |
| `DockWidget/` | Widget extension (`ParkItWidgets` bundle): the main widget, the Station widget, intents, `LocationFetcher` |
| `Shared/` | Source compiled into both app and widget (`DestinationEntity`, `StationEntity`, colors) |
| `Design/` | App icon generator (`make-icon.swift`), App Store listing copy |
| `docs/` | Support page and privacy policy (served by GitHub Pages) |

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
3. Allow location, star a few stations, then add widgets to your Home Screen or Lock Screen.

## Commands

```sh
xcodegen generate

# Simulator build, and a device compile check without signing
xcodebuild -project DockNearby.xcodeproj -scheme DockNearby -destination 'generic/platform=iOS Simulator' build
xcodebuild -project DockNearby.xcodeproj -scheme DockNearby -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build

# BikeKit unit tests (scratch path outside iCloud); LIVE_GBFS=1 adds a test against the real feed
cd BikeKit && swift test --scratch-path ~/Library/Caches/BikeKit-build
cd BikeKit && LIVE_GBFS=1 swift test --scratch-path ~/Library/Caches/BikeKit-build

# Regenerate the app icon
swift Design/make-icon.swift
```

## Gotchas

- **iCloud Drive + codesign:** this repo lives in an iCloud-synced folder. Keep build output in
  the default `~/Library/Developer/Xcode/DerivedData` — building *inside* the repo fails with
  "resource fork, Finder information, or similar detritus not allowed".
- Widgets reload about every 15 minutes at best (iOS rations reloads); the ↻ button forces one.
- No location in the widget? Check the app has permission. The widget falls back to the last
  location the app saw, then to 71st & Amsterdam.
- Widget extensions have a ~30 MB memory limit; BikeKit caches only the station fields it uses.

## Roadmap

Release checklist, device test list, and backlog live in [TODO.md](TODO.md).
