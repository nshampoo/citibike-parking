import SwiftUI

@main
struct DockNearbyApp: App {
    @State private var location = LocationModel()
    @State private var favorites = FavoritesStore()
    @State private var destinations = DestinationsStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if location.status == .notDetermined {
                    OnboardingView { location.requestPermission() }
                } else {
                    HomeView()
                }
            }
            .environment(location)
            .environment(favorites)
            .environment(destinations)
        }
    }
}
