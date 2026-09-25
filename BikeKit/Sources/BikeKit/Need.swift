import Foundation

/// What you're looking for at a station: somewhere to park, or a bike to ride.
public enum Need: String, Codable, Sendable, CaseIterable {
    case dock, anyBike, eBike, classicBike

    public var isBike: Bool { self != .dock }

    /// "1 dock", "7 e-bikes" — the unit for a count of this need.
    public func noun(for count: Int) -> String {
        let (one, many) = switch self {
        case .dock: ("dock", "docks")
        case .anyBike: ("bike", "bikes")
        case .eBike: ("e-bike", "e-bikes")
        case .classicBike: ("classic", "classics")
        }
        return count == 1 ? one : many
    }
}

extension NearbyStation {
    /// How many of `need` this station has right now. Bikes at a station that
    /// isn't renting count as zero — they're there, but you can't take one.
    public func count(of need: Need) -> Int {
        switch need {
        case .dock: docks
        case .anyBike: renting ? classic + ebikes : 0
        case .eBike: renting ? ebikes : 0
        case .classicBike: renting ? classic : 0
        }
    }

    public func has(_ need: Need) -> Bool { count(of: need) > 0 }
}
