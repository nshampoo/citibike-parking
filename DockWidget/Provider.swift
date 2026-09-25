import WidgetKit
import CoreLocation
import BikeKit

struct DockEntry: TimelineEntry {
    enum State { case loaded, failed, noFavorites, noDestination, noCommute }

    let date: Date
    let stations: [NearbyStation]
    let state: State

    static let sample = DockEntry(date: .now, stations: [
        NearbyStation(id: "1", name: "W 70 St & Amsterdam Ave", meters: 100, docks: 7, classic: 4, ebikes: 3, renting: true, capacity: 20,
                      latitude: 40.7780, longitude: -73.9819),
        NearbyStation(id: "2", name: "Amsterdam Ave & W 73 St", meters: 200, docks: 2, classic: 8, ebikes: 5, renting: true,
                      latitude: 40.7797, longitude: -73.9808),
        NearbyStation(id: "3", name: "Columbus Ave & W 72 St", meters: 280, docks: 0, classic: 10, ebikes: 9, renting: true,
                      latitude: 40.7780, longitude: -73.9777),
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
        var refresh = Date.now.addingTimeInterval(15 * 60)
        // Commute flips at 4am and noon; refresh right then rather than up to 15 minutes late.
        if config.mode == .commute { refresh = min(refresh, Commute.nextSwitch(after: .now)) }
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func entry(for config: DockConfig, in context: Context) async -> DockEntry {
        let count = switch context.family {
        case .accessoryInline: 2        // one line above the clock
        case .accessoryCircular: 1
        default: 3                      // rectangular: one dot per station
        }
        let favorites = SharedStore.favorites
        let here: CLLocation
        switch config.mode {
        case .favorites where favorites.isEmpty:
            return DockEntry(date: .now, stations: [], state: .noFavorites)
        case .destination:
            // Look it up fresh: the name or the destination itself may have changed in the app.
            guard let id = config.destination?.id,
                  let destination = SharedStore.destinations.first(where: { $0.id == id }) else {
                return DockEntry(date: .now, stations: [], state: .noDestination)
            }
            here = destination.location
        case .commute:
            guard let home = SharedStore.home, let work = SharedStore.work else {
                return DockEntry(date: .now, stations: [], state: .noCommute)
            }
            here = Commute.leg(at: .now) == .toWork ? work.location : home.location
        case .closest, .favorites:
            here = await LocationFetcher.current()
        }
        do {
            let stations = try await GBFSClient.shared.nearest(
                to: here, count: count, only: config.mode == .favorites ? favorites : nil,
                mustHave: config.needsRoom ? .dock : nil)
            return DockEntry(date: .now, stations: stations, state: .loaded)
        } catch {
            return DockEntry(date: .now, stations: [], state: .failed)
        }
    }
}
