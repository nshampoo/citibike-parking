# DockNearby

SwiftUI iOS 17+ app + WidgetKit extension showing open Citi Bike docks nearby. Shown to users as **Park It** (`CFBundleDisplayName`); code, targets, and bundle IDs stay DockNearby. See README.md for layout and setup.

## Rules
- `project.yml` (XcodeGen) is the source of truth. The `.xcodeproj`, Info.plists and entitlements are generated and gitignored — edit the YAML, then `xcodegen generate`.
- Swift 6 language mode, zero warnings. Keep it that way (check both simulator and device builds).
- App Group ID lives only in the `APP_GROUP_ID` build setting; code reads it via `AppGroup.id` (Info.plist `AppGroupID`). App ↔ widget shared keys go through `SharedStore` in BikeKit.
- Put testable logic in BikeKit as pure functions (see `GBFSClient.merge`) and cover it with Swift Testing.

## Commands
```sh
xcodegen generate
# Simulator build (use an iOS 26 sim — Xcode 26 can't target the installed iOS 17.4 sims)
xcodebuild -project DockNearby.xcodeproj -scheme DockNearby -destination 'generic/platform=iOS Simulator' build
# Device compile check without signing
xcodebuild -project DockNearby.xcodeproj -scheme DockNearby -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
# Package tests (scratch path outside iCloud)
cd BikeKit && swift test --scratch-path ~/Library/Caches/BikeKit-build
cd BikeKit && LIVE_GBFS=1 swift test --scratch-path ~/Library/Caches/BikeKit-build   # hits real feed
```

## Gotchas
- The repo is in an iCloud-synced folder. Never pass `-derivedDataPath` inside the repo: codesign fails with "resource fork, Finder information, or similar detritus not allowed". Use default DerivedData.
- XcodeGen sets some settings (e.g. `TARGETED_DEVICE_FAMILY`) at target level, which overrides project-level `settings` — set those per target.
- In AppIntents code, static metadata must be computed properties (`static var title: LocalizedStringResource { "..." }`), not stored `static var`, for Swift 6.
- Simulator verification: `xcrun simctl privacy <sim> grant location com.nick.docknearby` + `simctl location <sim> set 40.7781,-73.9820` skips the permission prompt.
