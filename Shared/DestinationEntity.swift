import AppIntents
import BikeKit

// Compiled into both the app and the widget (see project.yml), so widget
// settings and Siri pick destinations from the same list.

/// A saved destination as App Intents sees it — what shows up in pickers.
struct DestinationEntity: AppEntity {
    let id: UUID
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Destination" }
    static var defaultQuery: DestinationQuery { DestinationQuery() }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    init(_ destination: Destination) {
        id = destination.id
        name = destination.name
    }
}

struct DestinationQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [DestinationEntity] {
        SharedStore.destinations.filter { identifiers.contains($0.id) }.map(DestinationEntity.init)
    }

    func suggestedEntities() async throws -> [DestinationEntity] {
        SharedStore.destinations.map(DestinationEntity.init)
    }
}
