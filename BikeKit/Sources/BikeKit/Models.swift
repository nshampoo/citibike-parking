import Foundation

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

    public init(id: String, name: String, meters: Double, docks: Int, classic: Int, ebikes: Int, renting: Bool) {
        self.id = id
        self.name = name
        self.meters = meters
        self.docks = docks
        self.classic = classic
        self.ebikes = ebikes
        self.renting = renting
    }
}

/// Lightweight station for the app's searchable list.
public struct StationSummary: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let latitude: Double
    public let longitude: Double
}
