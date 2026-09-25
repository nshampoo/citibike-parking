import WidgetKit
import BikeKit

struct DockEntry: TimelineEntry {
    enum State { case loaded, failed, noFavorites }

    let date: Date
    let stations: [NearbyStation]
    let state: State

    static let sample = DockEntry(date: .now, stations: [
        NearbyStation(id: "1", name: "W 70 St & Amsterdam Ave", meters: 100, docks: 7, classic: 4, ebikes: 3, renting: true, capacity: 20),
        NearbyStation(id: "2", name: "Amsterdam Ave & W 73 St", meters: 200, docks: 2, classic: 8, ebikes: 5, renting: true),
        NearbyStation(id: "3", name: "Columbus Ave & W 72 St", meters: 280, docks: 0, classic: 10, ebikes: 9, renting: true),
    ], state: .loaded)
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DockEntry { .sample }

    func snapshot(for config: DockConfig, in context: Context) async -> DockEntry {
        // The widget gallery wants something instant; real devices get real data.
        context.isPreview ? .sample : await entry(for: config, in: context)
    }

    func timeline(for config: DockConfig, in context: Context) async -> Timeline<DockEntry> {
        let entry = await entry(for: config, in: context)
        return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
    }

    private func entry(for config: DockConfig, in context: Context) async -> DockEntry {
        let count = switch context.family {
        case .systemLarge: 6
        case .accessoryRectangular, .accessoryCircular, .accessoryInline: 1   // Lock Screen: closest only
        default: 3
        }
        let favorites = SharedStore.favorites
        if config.mode == .favorites && favorites.isEmpty {
            return DockEntry(date: .now, stations: [], state: .noFavorites)
        }
        let here = await LocationFetcher.current()
        do {
            let stations = try await GBFSClient.shared.nearest(
                to: here, count: count, only: config.mode == .favorites ? favorites : nil)
            return DockEntry(date: .now, stations: stations, state: .loaded)
        } catch {
            return DockEntry(date: .now, stations: [], state: .failed)
        }
    }
}
