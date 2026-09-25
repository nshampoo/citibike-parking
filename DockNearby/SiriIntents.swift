import AppIntents
import BikeKit

// "Hey Siri, how many docks at <station> in Park It" and
// "Docks near <destination> in Park It" (the app name comes from .applicationName). Also available in the Shortcuts app.

struct DocksAtStationIntent: AppIntent {
    static var title: LocalizedStringResource { "Docks at Station" }
    static var description: IntentDescription { "Open docks and bikes at a Citi Bike station right now." }

    @Parameter(title: "Station")
    var station: StationEntity

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
        guard let s = try await GBFSClient.shared.nearest(
            to: SharedStore.fallbackLocation, count: 1, only: [station.id]).first else {
            return .result(value: 0, dialog: "\(station.name) isn't reporting right now.")
        }
        return .result(value: s.docks,
                       dialog: "\(s.name) has \(s.docks) open docks, \(s.classic) bikes and \(s.ebikes) e-bikes.")
    }
}

struct DocksNearDestinationIntent: AppIntent {
    static var title: LocalizedStringResource { "Docks Near Destination" }
    static var description: IntentDescription { "Open docks at the three stations closest to a saved destination." }

    @Parameter(title: "Destination")
    var destination: DestinationEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let place = SharedStore.destinations.first(where: { $0.id == destination.id }) else {
            return .result(dialog: "I couldn't find that destination. Add it again in Park It.")
        }
        let stations = try await GBFSClient.shared.nearest(to: place.location, count: 3)
        let summary = stations.map { "\($0.shortName) has \($0.docks)" }.joined(separator: ", ")
        return .result(dialog: "Near \(place.name): \(summary).")
    }
}

struct DockNearbyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: DocksAtStationIntent(), phrases: [
            "How many docks at \(\.$station) in \(.applicationName)",
            "Check \(.applicationName) docks at \(\.$station)",
        ], shortTitle: "Docks at Station", systemImageName: "bicycle")

        AppShortcut(intent: DocksNearDestinationIntent(), phrases: [
            "Docks near \(\.$destination) in \(.applicationName)",
            "Check \(.applicationName) docks near \(\.$destination)",
        ], shortTitle: "Docks Near Destination", systemImageName: "flag")
    }
}
