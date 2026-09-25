import SwiftUI
import CoreLocation
import BikeKit

struct StationListView: View {
    @Environment(LocationModel.self) private var location
    @Environment(FavoritesStore.self) private var favorites
    @Environment(\.openURL) private var openURL

    @State private var stations: [StationSummary] = []
    @State private var query = ""
    @State private var loadError: String?

    var body: some View {
        let visible = filtered   // filter + sort once per render
        NavigationStack {
            List {
                if !location.isAuthorized { permissionBanner }

                let favs = visible.filter { favorites.contains($0.id) }
                if !favs.isEmpty {
                    Section("Favorites") { ForEach(favs) { row($0) } }
                }
                Section(location.location == nil ? "All stations" : "Nearby") {
                    ForEach(visible.filter { !favorites.contains($0.id) }) { row($0) }
                }
            }
            .navigationTitle("DockNearby")
            .searchable(text: $query, prompt: "Search stations")
            .overlay { overlay(isEmpty: visible.isEmpty) }
            .task { await load() }
            .refreshable {
                location.refresh()
                await load()
            }
        }
    }

    // MARK: Data

    /// Search-filtered, then sorted by distance when we know where the user is.
    private var filtered: [StationSummary] {
        let matches = query.isEmpty ? stations : stations.filter { $0.name.localizedStandardContains(query) }
        guard let here = location.location else { return matches }
        return matches.sorted { distance($0, from: here) < distance($1, from: here) }
    }

    private func load() async {
        do {
            stations = try await GBFSClient.shared.allStations()
            loadError = nil
        } catch {
            loadError = "Couldn't load stations. Pull to retry."
        }
    }

    private func distance(_ s: StationSummary, from here: CLLocation) -> CLLocationDistance {
        here.distance(from: CLLocation(latitude: s.latitude, longitude: s.longitude))
    }

    // MARK: Views

    private func row(_ s: StationSummary) -> some View {
        let starred = favorites.contains(s.id)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(s.name)
                if let here = location.location {
                    Text(Measurement(value: distance(s, from: here), unit: UnitLength.meters),
                         format: .measurement(width: .abbreviated, usage: .road))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button { favorites.toggle(s.id) } label: {
                Image(systemName: starred ? "star.fill" : "star")
                    .foregroundStyle(starred ? .yellow : .secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(starred ? "Remove from favorites" : "Add to favorites")
        }
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
