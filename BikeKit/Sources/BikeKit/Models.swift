import Foundation
import CoreLocation

// MARK: - Raw GBFS 1.1 shapes (decoded with .convertFromSnakeCase)

struct GBFS<T: Decodable>: Decodable { let data: T }
struct InfoData: Decodable { let stations: [StationInfo] }
struct StatusData: Decodable { let stations: [StationStatus] }

/// Static station data. Also `Encodable` so we can cache a slim copy
/// (just these fields) instead of the 1.3 MB feed.
struct StationInfo: Codable, Sendable {
    let stationId: String
    let name: String
    let lat: Double
    let lon: Double
    let capacity: Int?
}

struct StationStatus: Decodable, Sendable {
    let stationId: String
    let numBikesAvailable: Int
    let numEbikesAvailable: Int?
    let numDocksAvailable: Int
    let isInstalled: Int
    let isRenting: Int
    let isReturning: Int
}

// MARK: - Public types used by the app and widget

/// A station joined with its live status and distance from the user.
public struct NearbyStation: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let meters: Double
    public let docks: Int
    public let classic: Int
    public let ebikes: Int
    public let renting: Bool
    /// Total docks, when the feed reports a real value (some stations report 0).
    public let capacity: Int?
    public let latitude: Double
    public let longitude: Double

    public init(id: String, name: String, meters: Double, docks: Int, classic: Int, ebikes: Int,
                renting: Bool, capacity: Int? = nil, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.meters = meters
        self.docks = docks
        self.classic = classic
        self.ebikes = ebikes
        self.renting = renting
        self.capacity = capacity
        self.latitude = latitude
        self.longitude = longitude
    }

    /// "Has room" means at least this many open docks — one might be gone by the time you arrive.
    public static let roomMinimum = 2
    public var hasRoom: Bool { docks >= Self.roomMinimum }

    public var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }

    public func distance(from here: CLLocation) -> CLLocationDistance {
        here.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }
}

/// A saved place ("Work", "Home") whose nearby docks you want to see before you get there.
public struct Destination: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public let latitude: Double
    public let longitude: Double

    public init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    public var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }
    public var coordinate: CLLocationCoordinate2D { location.coordinate }
}
