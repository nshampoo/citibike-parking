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

    /// At least one open dock.
    public var hasRoom: Bool { docks > 0 }

    public var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }

    public func distance(from here: CLLocation) -> CLLocationDistance {
        here.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }

    /// Whether `here` is within `radius` of any station — i.e. somewhere Citi Bike operates.
    /// Unknown (true) until stations have loaded, so nothing flickers on launch.
    public static func serviceArea(_ stations: [NearbyStation], contains here: CLLocation,
                                   radius: CLLocationDistance = 50_000) -> Bool {
        stations.isEmpty || stations.contains { $0.distance(from: here) <= radius }
    }
}

/// A saved place whose nearby docks you want to see before you get there.
/// Home and Work are special: at most one of each, and they power commute mode.
public struct Destination: Codable, Identifiable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable, Identifiable {
        case home, work, other
        public var id: Self { self }
    }

    public let id: UUID
    public var name: String
    public var kind: Kind
    public let latitude: Double
    public let longitude: Double

    public init(id: UUID = UUID(), name: String, kind: Kind = .other, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.kind = kind
        self.latitude = latitude
        self.longitude = longitude
    }

    // Places saved before Home/Work existed have no "kind"; treat them as .other.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        kind = try c.decodeIfPresent(Kind.self, forKey: .kind) ?? .other
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)
    }

    public var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }
    public var coordinate: CLLocationCoordinate2D { location.coordinate }
}
