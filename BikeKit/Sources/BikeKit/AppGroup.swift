import Foundation
import CoreLocation

/// Shared storage between the app and the widget extension.
public enum AppGroup {
    /// Read from Info.plist (`AppGroupID`), which XcodeGen fills from the
    /// `APP_GROUP_ID` build setting — so the ID lives in exactly one place.
    public static let id: String =
        Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String
        ?? "group.com.nick.docknearby"

    public static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

/// Typed accessors for the values the app and widget both read/write.
public enum SharedStore {
    private static let favoritesKey = "favorites"
    private static let lastLocationKey = "lastLoc"

    /// Favorite station IDs, starred in the app and read by the widget.
    public static var favorites: Set<String> {
        get { Set(AppGroup.defaults.stringArray(forKey: favoritesKey) ?? []) }
        set { AppGroup.defaults.set(newValue.sorted(), forKey: favoritesKey) }
    }

    /// Last known user location, used when the widget can't get a fresh fix.
    public static var lastLocation: CLLocation? {
        get {
            guard let c = AppGroup.defaults.array(forKey: lastLocationKey) as? [Double], c.count == 2 else { return nil }
            return CLLocation(latitude: c[0], longitude: c[1])
        }
        set {
            if let loc = newValue {
                AppGroup.defaults.set([loc.coordinate.latitude, loc.coordinate.longitude], forKey: lastLocationKey)
            } else {
                AppGroup.defaults.removeObject(forKey: lastLocationKey)
            }
        }
    }

    /// 71st & Amsterdam — used before we've ever had a location.
    public static let fallbackLocation = CLLocation(latitude: 40.7781, longitude: -73.9820)
}
