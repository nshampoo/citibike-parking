import SwiftUI
import MapKit
import BikeKit

/// State shared by the map and the station sheet floating over it.
@Observable
@MainActor
final class HomeModel {
    /// Sheet heights: just search + the two chip rows, half the screen, full screen.
    static let peek = PresentationDetent.height(176)
    static let half = PresentationDetent.fraction(0.45)

    static let followUser = MapCameraPosition.userLocation(
        fallback: .region(MKCoordinateRegion(center: SharedStore.fallbackLocation.coordinate,
                                             latitudinalMeters: 1_500, longitudinalMeters: 1_500)))

    private(set) var stations: [NearbyStation] = []
    private(set) var loadError: String?
    var query = ""
    var selectedID: String?
    /// When set, the map and list center on this place instead of on you.
    private(set) var destination: Destination?
    var camera = HomeModel.followUser
    var visibleRegion: MKCoordinateRegion?
    var detent = HomeModel.half
    var showingAbout = false

    var selected: NearbyStation? { stations.first { $0.id == selectedID } }

    /// The user's location if Citi Bike operates there; nil if unknown or far away
    /// (say, an App Store reviewer in Cupertino), so we don't show "2,500 mi" everywhere.
    func usable(_ location: CLLocation?) -> CLLocation? {
        guard let location, NearbyStation.serviceArea(stations, contains: location) else { return nil }
        return location
    }

    /// Outside the service area, stop following the user onto an empty map and show NYC.
    func keepCameraInServiceArea(user: CLLocation?) {
        guard let user, usable(user) == nil, camera.followsUserLocation else { return }
        camera = .region(MKCoordinateRegion(center: SharedStore.fallbackLocation.coordinate,
                                            latitudinalMeters: 1_500, longitudinalMeters: 1_500))
    }

    func load(near here: CLLocation?) async {
        do {
            stations = try await GBFSClient.shared.stations(near: here ?? SharedStore.fallbackLocation)
            loadError = nil
        } catch {
            loadError = "Couldn't load stations. Pull to retry."
        }
    }

    /// Opens the station card. From the list we also bring the station into view;
    /// from a pin it's already on screen.
    func select(_ s: NearbyStation, moveMap: Bool) {
        selectedID = s.id
        if detent == Self.peek { detent = Self.half }
        if moveMap { fly(to: s.coordinate, meters: 800) }
    }

    func show(_ d: Destination) {
        destination = d
        selectedID = nil
        fly(to: d.coordinate, meters: 1_000)
    }

    func clearDestination() {
        destination = nil
        withAnimation { camera = Self.followUser }
    }

    /// Centers `coordinate` in the part of the map the half-height sheet leaves visible,
    /// by shifting the region's center south.
    private func fly(to coordinate: CLLocationCoordinate2D, meters: Double) {
        let span = MKCoordinateRegion(center: coordinate, latitudinalMeters: meters, longitudinalMeters: meters).span
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude - span.latitudeDelta * 0.225,
                                            longitude: coordinate.longitude)
        withAnimation { camera = .region(MKCoordinateRegion(center: center, span: span)) }
    }
}
