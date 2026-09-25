import SwiftUI
import MapKit
import BikeKit

/// Map on top, nearby list below. Tapping a pin or a row opens the station sheet.
struct HomeView: View {
    @Environment(LocationModel.self) private var location
    @Environment(FavoritesStore.self) private var favorites
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var stations: [NearbyStation] = []
    @State private var loadError: String?
    @State private var query = ""
    @State private var selectedID: String?
    @State private var camera: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(center: SharedStore.fallbackLocation.coordinate,
                                             latitudinalMeters: 1_500, longitudinalMeters: 1_500)))
    @State private var visibleRegion: MKCoordinateRegion?
    /// Per-device preference, so plain UserDefaults (not the App Group) is enough.
    @AppStorage("onlyWithRoom") private var onlyWithRoom = false

    /// SwiftUI maps slow down with thousands of annotations, so draw at most this many.
    private static let maxPins = 150
    private static let nearbyCount = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                map.containerRelativeFrame(.vertical) { height, _ in height * 0.45 }
                list
            }
            .navigationTitle("DockNearby")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search stations")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { roomFilterButton }
            }
            .sheet(item: selection) { station in
                StationDetailView(station: station, here: location.location)
                    .presentationDetents([.height(250)])
                    // Keep the map usable while the sheet is up, so you can tap another pin.
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(250)))
            }
            .task { await load() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await load() } }
            }
        }
    }

    // MARK: Map

    private var map: some View {
        Map(position: $camera) {
            UserAnnotation()
            ForEach(pins) { s in
                Annotation(s.name, coordinate: s.coordinate) {
                    StationPin(docks: s.docks, isFavorite: favorites.contains(s.id), isSelected: s.id == selectedID,
                               isDimmed: onlyWithRoom && !s.hasRoom)
                        .onTapGesture { selectedID = s.id }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { visibleRegion = $0.region }
    }

    /// Stations inside the visible region; if there are too many, the ones nearest its center.
    private var pins: [NearbyStation] {
        guard let r = visibleRegion else { return [] }
        let inView = stations.filter {
            abs($0.latitude - r.center.latitude) <= r.span.latitudeDelta / 2
                && abs($0.longitude - r.center.longitude) <= r.span.longitudeDelta / 2
        }
        guard inView.count > Self.maxPins else { return inView }
        let center = CLLocation(latitude: r.center.latitude, longitude: r.center.longitude)
        return Array(inView.sorted { $0.distance(from: center) < $1.distance(from: center) }.prefix(Self.maxPins))
    }

    // MARK: List

    private var list: some View {
        let here = location.location
        // Distance from the user when known; alphabetical otherwise.
        let sorted = here.map { h in stations.sorted { $0.distance(from: h) < $1.distance(from: h) } }
            ?? stations.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let matches = query.isEmpty ? sorted : sorted.filter { $0.name.localizedStandardContains(query) }
        let favs = matches.filter { favorites.contains($0.id) }
        // Favorites always show; the room filter only trims the rest.
        let others = matches.filter { !favorites.contains($0.id) && (!onlyWithRoom || $0.hasRoom) }

        return List {
            if !location.isAuthorized { permissionBanner }
            if !favs.isEmpty {
                Section("Favorites") { ForEach(favs) { row($0, here: here) } }
            }
            Section(query.isEmpty ? (here == nil ? "Stations" : "Nearby") : "Results") {
                // Without a search, only the closest few — the map covers the rest.
                ForEach(query.isEmpty ? Array(others.prefix(Self.nearbyCount)) : others) { row($0, here: here) }
            }
        }
        .listStyle(.plain)
        .overlay { overlay(isEmpty: matches.isEmpty) }
        .refreshable {
            location.refresh()
            await load()
        }
    }

    private func row(_ s: NearbyStation, here: CLLocation?) -> some View {
        Button { select(s) } label: {
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
    }

    /// From the list: open the sheet and bring the station into view on the map.
    private func select(_ s: NearbyStation) {
        selectedID = s.id
        withAnimation {
            camera = .region(MKCoordinateRegion(center: s.coordinate, latitudinalMeters: 800, longitudinalMeters: 800))
        }
    }

    private var selection: Binding<NearbyStation?> {
        Binding(get: { stations.first { $0.id == selectedID } },
                set: { selectedID = $0?.id })
    }

    // MARK: Data

    private func load() async {
        do {
            stations = try await GBFSClient.shared.stations(near: location.location ?? SharedStore.fallbackLocation)
            loadError = nil
        } catch {
            loadError = "Couldn't load stations. Pull to retry."
        }
    }

    // MARK: Views

    private var roomFilterButton: some View {
        Button { onlyWithRoom.toggle() } label: {
            Image(systemName: onlyWithRoom ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel(onlyWithRoom ? "Show all stations" : "Only stations with room")
    }

    private var permissionBanner: some View {
        Section {
            Label("Location is off, so the widget uses your last known spot.", systemImage: "location.slash")
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        }
    }

    @ViewBuilder private func overlay(isEmpty: Bool) -> some View {
        if stations.isEmpty {
            if let loadError {
                ContentUnavailableView("No Connection", systemImage: "wifi.slash", description: Text(loadError))
            } else {
                ProgressView()
            }
        } else if isEmpty {
            ContentUnavailableView.search(text: query)
        }
    }
}

/// Green plenty, orange few, red none — same scale as the home screen widget.
func dockColor(_ docks: Int) -> Color { docks == 0 ? .red : docks <= 3 ? .orange : .green }

/// A map pin: a dot showing the open-dock count, with a star badge for favorites.
struct StationPin: View {
    let docks: Int
    let isFavorite: Bool
    let isSelected: Bool
    var isDimmed = false

    var body: some View {
        Text("\(docks)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(dockColor(docks), in: .circle)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .overlay(alignment: .topTrailing) {
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                        .shadow(radius: 1)
                        .offset(x: 5, y: -5)
                }
            }
            .opacity(isDimmed ? 0.35 : 1)
            .scaleEffect(isSelected ? 1.35 : 1)
            .animation(.snappy, value: isSelected)
            .shadow(radius: 2)
    }
}
