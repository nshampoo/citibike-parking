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
    @State private var addingDestination = false

    /// Without a search, only the closest few — the map covers the rest.
    private static let nearbyCount = 30

    var body: some View {
        Group {
            if let station = model.selected {
                StationDetailView(station: station, here: location.location) { model.selectedID = nil }
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
        .sheet(isPresented: $addingDestination) {
            NavigationStack { AddDestinationView() }
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

    /// "Open docks" filter, then saved places (tap to see docks there, long-press to delete), then +.
    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "Open docks", systemImage: "parkingsign.circle", isOn: onlyWithRoom) {
                    onlyWithRoom.toggle()
                }
                ForEach(destinations.all) { d in
                    let isOn = model.destination?.id == d.id
                    Chip(title: d.name, systemImage: icon(for: d.name), isOn: isOn) {
                        isOn ? model.clearDestination() : model.show(d)
                    }
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            if isOn { model.clearDestination() }
                            destinations.remove(d.id)
                        }
                    }
                }
                Chip(title: destinations.all.isEmpty ? "Add place" : nil, systemImage: "plus", isOn: false) {
                    addingDestination = true
                }
                .accessibilityLabel("Add place")
            }
            .padding(.horizontal)
        }
    }

    private func icon(for name: String) -> String {
        switch name.lowercased() {
        case let n where n.contains("home"): "house.fill"
        case let n where n.contains("work") || n.contains("office"): "briefcase.fill"
        default: "mappin"
        }
    }

    // MARK: List

    private var list: some View {
        // Distance from the destination or the user when known; alphabetical otherwise.
        let here = model.destination?.location ?? location.location
        let sorted = here.map { h in model.stations.sorted { $0.distance(from: h) < $1.distance(from: h) } }
            ?? model.stations.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let matches = model.query.isEmpty ? sorted : sorted.filter { $0.name.localizedStandardContains(model.query) }
        let favs = matches.filter { favorites.contains($0.id) }
        // Favorites always show; the room filter only trims the rest.
        let others = matches.filter { !favorites.contains($0.id) && (!onlyWithRoom || $0.hasRoom) }

        return List {
            if model.destination == nil && !location.isAuthorized { permissionBanner }
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
            Label("Location is off, so the widget uses your last known spot.", systemImage: "location.slash")
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

/// A capsule toggle under the search bar. Filled when on.
struct Chip: View {
    let title: String?
    let systemImage: String
    let isOn: Bool
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
            .foregroundStyle(isOn ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .background(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
