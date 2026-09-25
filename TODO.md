# Park It — TODO

Where things stand (Sept 24, 2026): the app is feature-complete for v1 and review-proofed.
What's left is App Store setup, device testing, and marketing screenshots.
Listing copy lives in [Design/app-store-listing.md](Design/app-store-listing.md).

## 🚀 Release — your steps

- [ ] **Enroll in the Apple Developer Program** ($99/yr). The free Personal Team can't ship to TestFlight or the App Store.
  - [ ] Then tell Claude the new Team ID: it goes in `project.yml` (`DEVELOPMENT_TEAM`).
  - [ ] Decide on the bundle ID now (`com.nick.docknearby` → something else?). It can't change after the first upload.
- [ ] **Read Citi Bike's data license** (Lyft's GBFS data sharing policy). Check attribution requirements and rules on using the name.
- [ ] **Decide: `citibike` in keywords?** It's a trademark, so there's rejection or takedown risk (guideline 2.3.7). There's room for it (92/100 characters used).
- [ ] **Turn on GitHub Pages**: repo Settings → Pages → Branch `main`, folder `/docs`. The repo must be public on a free account. Check that these load:
  - Support: https://nshampoo.github.io/citibike-parking/
  - Privacy: https://nshampoo.github.io/citibike-parking/privacy.html
- [ ] **App Store Connect**: create the app record.
  - [ ] Check that "Park It" is available (backup: "Park It: Bike Dock Finder")
  - [ ] Paste the subtitle, promo text, keywords and description from the listing doc
  - [ ] Categories: Navigation / Travel · Age rating 4+ · App Privacy: **Data Not Collected**
  - [ ] Paste the App Review notes (the out-of-NYC explanation) from the listing doc
- [ ] **Take a Lock Screen screenshot on your phone** with the rectangular widget showing (side button + volume up). Needed for slide 3.

## 📱 Test on your phone (TestFlight, or run from Xcode)

These have compiled cleanly but have never been used on a real device:

- [ ] (i) button opens the About popup
- [ ] Tap a pin → station card → **Favorite** and **Directions** (opens Apple Maps in cycling mode)
- [ ] Drag the sheet between peek / half / full; tapping search expands it
- [ ] **Set Home / Set Work** from the chips; long-press → Change… / Delete; **+** to add another place
- [ ] Tap a place chip → map flies there, list shows "Near Work"; tap again to go back
- [ ] **Open docks** chip dims full pins and hides them from the list
- [ ] **Park | Ride** switch; in Ride, **E-bikes** / **Classic** chips (tap again for any bike); counts on pins, rows, card
- [ ] Widget **Count** setting: Parking / Any bike / E-bikes / Classic — label in the top row matches
- [ ] **Home screen widgets** (small / medium / large): header "PARKING · Nearby", ↻ refresh, colored counts; try each mode
- [ ] **Station widget** (small / medium): defaults to nearest favorite; Edit Widget → pick any station (search works?)
- [ ] Lock Screen widget, rectangular:
  - [ ] "now ↻" is right-aligned with no gap
  - [ ] tapping ↻ refreshes the counts
  - [ ] dots show the numbers cut out of solid circles
- [ ] Widget modes: Closest / Favorites / Near a destination / **Commute** (flips at 4am and noon)
- [ ] Siri: "How many docks at … in Park It", "Docks near Work in Park It"
- [ ] Dark mode map looks right (graphite wash, grey pins)
- [ ] VoiceOver reads pins as "name, N open docks"

## 🎨 Screenshots — Claude's steps

- [ ] **Re-take the raw screenshots** on the iPhone 17 Pro Max simulator (1320 × 2868). Warm up the map first; the first attempt came out blank.
  Debug-only launch options stage the scenes: `-screenshotCard`, `-screenshotPlaces`.
- [ ] **Build the "story" screenshot generator**: a script, like `Design/make-icon.swift`, that puts each shot in a tilted phone outline on a graphite → blue background with a big caption. Output is ready to upload.
- [ ] Story draft (edit the captions!):
  1. "Never ride up to a full dock." — live map
  2. "Every station, live." — station card
  3. "Check without unlocking." — Lock Screen widget *(needs your phone screenshot)*
  4. "Your commute, handled." — Home/Work chips, docks near Work
  5. "Easy on the eyes at night." — dark map
- [ ] After enrollment: update the team ID, then archive → upload to TestFlight together.

## ✨ Small polish (optional, quick)

- [ ] Use the icon's blue as the app's accent color (location button, chips, selected states)
- [ ] Rounded numbers in the list's dock counts, to match the pins
- [ ] Refresh the widget whenever the app opens
- [ ] Inline Lock Screen widget: prefix "Work:" / "Home:" in Commute mode
- [ ] Short-name clashes: two favorites on the same street both show "70th". Add the cross street?

## 💡 Future ideas (backlog)

- **Last-mile planner:** subway most of the way, then Citi Bike the rest.
  v1: the best dock near the destination plus the best bike pickup station. v2: compare subway travel times (MapKit can only give transit *times*, not routes, so the transit leg hands off to Apple Maps).
- **Walk-from-dock time** in destination view
- **Ride Live Activity:** live dock counts at your destination while you ride
- **Apple Watch:** docks at your stop at a glance
- Grouped pins when zoomed far out
- Skipped on purpose: "usually full at 9am" predictions (needs a server), push alerts (iOS background limits)

## 🧹 Housekeeping

- [ ] Rewrite the first commit (`0a3060f`) to drop its Claude co-author line? That needs a force-push, so it's your call.
- [ ] Delete the leftover folder at the old path `Documents - Nicholas's MacBook Pro/CitiBike-Parking` (it only has Xcode user state).
