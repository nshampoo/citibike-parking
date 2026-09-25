import Observation
import CoreLocation
import WidgetKit
import AppIntents
import BikeKit

/// Saved destinations, persisted to the App Group so widget settings and Siri can list them.
@Observable
@MainActor
final class DestinationsStore {
    private(set) var all: [Destination] = SharedStore.destinations

    var home: Destination? { all.first { $0.kind == .home } }
    var work: Destination? { all.first { $0.kind == .work } }
    var others: [Destination] { all.filter { $0.kind == .other } }

    /// Adds a place. Home and Work replace any existing one of the same kind.
    func add(name: String, kind: Destination.Kind = .other, at coordinate: CLLocationCoordinate2D) {
        if kind != .other { all.removeAll { $0.kind == kind } }
        all.append(Destination(name: name, kind: kind, latitude: coordinate.latitude, longitude: coordinate.longitude))
        save()
    }

    func remove(_ id: Destination.ID) {
        all.removeAll { $0.id == id }
        save()
    }

    private func save() {
        SharedStore.destinations = all
        WidgetCenter.shared.reloadAllTimelines()
        // Siri learns spoken phrases from suggestedEntities; refresh them when the list changes.
        DockNearbyShortcuts.updateAppShortcutParameters()
    }
}
