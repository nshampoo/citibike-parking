import SwiftUI
import CoreLocation
import BikeKit

/// The sheet over the map: search, filter/place chips, and the station list —
/// or, once a station is picked, its card.
struct StationsSheet: View {
    @Bindable var model: HomeModel
    @Environment(LocationModel.self) private var location
    @Environment(FavoritesStore.self) private var favorites
    @Environment(DestinationsStore.self) private var destinations
    @Environment(\.openURL) private var openURL
    @AppStorage("onlyWithRoom") private var onlyWithRoom = false

    @FocusState private var searchFocused: Bool
    /// Which kind of place the add screen is open for, if any.
    @State private var adding: Destination.Kind?

    /// Without a search, only the closest few — the map covers the rest.
    private static let nearbyCount = 30

    var body: some View {
        Group {
            if let station = model.selected {
                StationDetailView(station: station, here: model.usable(location.location)) { model.selectedID = nil }
            } else {
                VStack(spacing: 12) {
                    searchField.padding(.horizontal)
                    chips
                    list
                }
                .padding(.top, 20)
            }
        }
        .onChange(of: searchFocused) { _, focused in
            if focused { model.detent = .large }
        }
        .sheet(item: $adding) { kind in
            NavigationStack { AddDestinationView(kind: kind) }
        }
        .sheet(isPresented: $model.showingAbout) { AboutView() }
    }

    // MARK: Header

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search stations", text: $model.query)
                .focused($searchFocused)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !model.query.isEmpty {
                Button { model.query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.fill.tertiary, in: .capsule)
    }

    /// "Open docks" filter, Home and Work, other saved places, then +.
    /// Tap a place to see docks there; long-press to change or delete it.
    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "Open docks", systemImage: "parkingsign.circle", isOn: onlyWithRoom) {
                    onlyWithRoom.toggle()
                }
                fixedPlaceChip(.home, destinations.home)
                fixedPlaceChip(.work, destinations.work)
                ForEach(destinations.others) { placeChip($0, icon: "mappin") }
                Chip(title: destinations.others.isEmpty ? "Add place" : nil, systemImage: "plus", isOn: false) {
                    adding = .other
                }
                .accessibilityLabel("Add place")
            }
            .padding(.horizontal)
        }
    }

    /// Home or Work: "Set Home" until it's saved, then a normal place chip.
    @ViewBuilder private func fixedPlaceChip(_ kind: Destination.Kind, _ place: Destination?) -> some View {
        let icon = kind == .home ? "house" : "briefcase"
        if let place {
            placeChip(place, icon: icon + ".fill")
        } else {
            Chip(title: kind == .home ? "Set Home" : "Set Work", systemImage: icon, isOn: false, isMuted: true) {
                adding = kind
            }
        }
    }

    private func placeChip(_ d: Destination, icon: String) -> some View {
        let isOn = model.destination?.id == d.id
        return Chip(title: d.name, systemImage: icon, isOn: isOn) {
            isOn ? model.clearDestination() : model.show(d)
        }
        .contextMenu {
            if d.kind != .other {
                Button("Change \(d.name)…", systemImage: "pencil") { adding = d.kind }
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                if isOn { model.clearDestination() }
                destinations.remove(d.id)
            }
        }
    }

    // MARK: List

    private var list: some View {
        // Distances from the destination or the user when known. Otherwise (no location, or
        // outside Citi Bike's area) sort around the default spot the map shows, without distances.
        let userHere = model.usable(location.location)
        let here = model.destination?.location ?? userHere
        let reference = here ?? SharedStore.fallbackLocation
        let sorted = model.stations.sorted { $0.distance(from: reference) < $1.distance(from: reference) }
        let matches = model.query.isEmpty ? sorted : sorted.filter { $0.name.localizedStandardContains(model.query) }
        let favs = matches.filter { favorites.contains($0.id) }
        // Favorites always show; the room filter only trims the rest.
        let others = matches.filter { !favorites.contains($0.id) && (!onlyWithRoom || $0.has(.dock)) }

        return List {
            if model.destination == nil {
                if !location.isAuthorized {
                    permissionBanner
                } else if location.location != nil && userHere == nil {
                    Label("You're outside Citi Bike's service area, so this shows New York.", systemImage: "globe.americas")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
            }
            if !favs.isEmpty {
                Section("Favorites") { ForEach(favs) { row($0, here: here) } }
            }
            Section(sectionTitle(hasLocation: here != nil)) {
                ForEach(model.query.isEmpty ? Array(others.prefix(Self.nearbyCount)) : others) { row($0, here: here) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .overlay { overlay(isEmpty: matches.isEmpty) }
        .refreshable {
            location.refresh()
            await model.load(near: location.location)
        }
    }

    private func sectionTitle(hasLocation: Bool) -> String {
        if !model.query.isEmpty { return "Results" }
        if let destination = model.destination { return "Near \(destination.name)" }
        return hasLocation ? "Nearby" : "Stations"
    }

    private func row(_ s: NearbyStation, here: CLLocation?) -> some View {
        Button {
            searchFocused = false
            model.select(s, moveMap: true)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.name)
                    if let here {
                        Text(Measurement(value: s.distance(from: here), unit: UnitLength.meters),
                             format: .measurement(width: .abbreviated, usage: .road))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(s.docks)").font(.headline).foregroundStyle(dockColor(s.docks))
                Text("docks").font(.caption).foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
        .listRowBackground(Color.clear)
    }

    private var permissionBanner: some View {
        Section {
            Label("Location is off, so Park It uses your last known spot.", systemImage: "location.slash")
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder private func overlay(isEmpty: Bool) -> some View {
        if model.stations.isEmpty {
            if let loadError = model.loadError {
                ContentUnavailableView("No Connection", systemImage: "wifi.slash", description: Text(loadError))
            } else {
                ProgressView()
            }
        } else if isEmpty {
            ContentUnavailableView.search(text: model.query)
        }
    }
}

/// A capsule toggle under the search bar. Filled when on; muted for not-yet-set places.
struct Chip: View {
    let title: String?
    let systemImage: String
    let isOn: Bool
    var isMuted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let title {
                    Label(title, systemImage: systemImage)
                } else {
                    Image(systemName: systemImage)
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isOn ? AnyShapeStyle(.white) : isMuted ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
            .background(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
