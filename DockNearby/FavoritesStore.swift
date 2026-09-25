import Observation
import WidgetKit
import AppIntents
import BikeKit

/// Starred station IDs, persisted to the App Group so the widget can read them.
@Observable
@MainActor
final class FavoritesStore {
    private(set) var ids: Set<String> = SharedStore.favorites

    func contains(_ id: String) -> Bool { ids.contains(id) }

    func toggle(_ id: String) {
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        SharedStore.favorites = ids
        WidgetCenter.shared.reloadAllTimelines()
        // Siri learns spoken phrases from suggestedEntities; refresh them when the list changes.
        DockNearbyShortcuts.updateAppShortcutParameters()
    }
}
