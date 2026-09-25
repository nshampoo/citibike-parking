import AppIntents
import BikeKit

// Compiled into both the app (Siri / Shortcuts) and the widget (the Station widget's picker).

/// A Citi Bike station as App Intents sees it.
struct StationEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Station" }
    static var defaultQuery: StationQuery { StationQuery() }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct StationQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [StationEntity] {
        let names = try await GBFSClient.shared.stationNames()
        return identifiers.compactMap { id in names[id].map { StationEntity(id: id, name: $0) } }
    }

    /// Typing in the Shortcuts picker searches every station by name.
    func entities(matching string: String) async throws -> [StationEntity] {
        try await GBFSClient.shared.stationNames()
            .filter { $0.value.localizedStandardContains(string) }
            .map { StationEntity(id: $0.key, name: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Favorites — also the stations Siri learns for the spoken phrase.
    func suggestedEntities() async throws -> [StationEntity] {
        let favorites = SharedStore.favorites
        return try await entities(for: Array(favorites))
    }
}
