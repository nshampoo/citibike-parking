import SwiftUI

@main
struct DockNearbyApp: App {
    @State private var location = LocationModel()
    @State private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if location.status == .notDetermined {
                    OnboardingView { location.requestPermission() }
                } else {
                    StationListView()
                }
            }
            .environment(location)
            .environment(favorites)
        }
    }
}
