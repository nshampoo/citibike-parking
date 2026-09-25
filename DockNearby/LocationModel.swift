import CoreLocation
import Observation
import WidgetKit
import BikeKit

/// Owns location permission for the app. Granting it here is what unlocks
/// location for the widget, too.
@Observable
@MainActor
final class LocationModel: NSObject, CLLocationManagerDelegate {
    private(set) var status: CLAuthorizationStatus
    private(set) var location: CLLocation? = SharedStore.lastLocation

    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isAuthorized: Bool { status == .authorizedWhenInUse || status == .authorizedAlways }

    func requestPermission() { manager.requestWhenInUseAuthorization() }

    func refresh() { if isAuthorized { manager.requestLocation() } }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        let newStatus = m.authorizationStatus
        Task { @MainActor in
            status = newStatus
            refresh()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let last = locs.last else { return }
        Task { @MainActor in
            location = last
            SharedStore.lastLocation = last   // widget fallback
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {}
}
