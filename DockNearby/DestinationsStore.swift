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

    func add(name: String, at coordinate: CLLocationCoordinate2D) {
        all.append(Destination(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude))
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        all.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        SharedStore.destinations = all
        WidgetCenter.shared.reloadAllTimelines()
        // Siri learns spoken phrases from suggestedEntities; refresh them when the list changes.
        DockNearbyShortcuts.updateAppShortcutParameters()
    }
}
