import CoreLocation
import BikeKit

/// One-shot location for the widget. Falls back to the last location the
/// app saved, then to 71st & Amsterdam.
@MainActor
final class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    static func current() async -> CLLocation {
        if let loc = await LocationFetcher().request() {
            SharedStore.lastLocation = loc
            return loc
        }
        return SharedStore.lastLocation ?? SharedStore.fallbackLocation
    }

    private func request() async -> CLLocation? {
        // True only if the app has permission and Info.plist has NSWidgetWantsLocation.
        guard manager.isAuthorizedForWidgetUpdates else { return nil }
        return await withCheckedContinuation { c in
            continuation = c
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.requestLocation()
            // Widgets get limited run time; don't wait forever for a fix.
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(10))
                self?.finish(nil)
            }
        }
    }

    /// Resumes at most once — whichever of success, failure, or timeout comes first.
    private func finish(_ location: CLLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
    }

    // Core Location calls these on the thread that created the manager (main),
    // but the protocol isn't MainActor-annotated, so hop explicitly.
    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        let last = locs.last
        Task { @MainActor in finish(last) }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in finish(nil) }
    }
}
