import Foundation

/// The app's Park | Ride filters. Each mode keeps its own settings, so switching
/// back and forth brings back whatever you last used there.
public struct Filters: Codable, Equatable, Sendable {
    public var isRiding = false
    /// Ride's bike type: .anyBike, .eBike, or .classicBike.
    public private(set) var bikeKind = Need.anyBike
    public var hideFullParking = false
    public var hideEmptyBikes = false

    public init() {}

    /// What the map and list count right now.
    public var need: Need { isRiding ? bikeKind : .dock }

    /// The hide-empty chip for the current mode.
    public var hideEmpty: Bool {
        get { isRiding ? hideEmptyBikes : hideFullParking }
        set { if isRiding { hideEmptyBikes = newValue } else { hideFullParking = newValue } }
    }

    /// Tap E-bikes or Classic: narrow to that kind, or back to any bike if it's already on.
    public mutating func toggleBikeKind(_ kind: Need) {
        guard kind == .eBike || kind == .classicBike else { return }
        bikeKind = bikeKind == kind ? .anyBike : kind
    }
}

// Explicit coding: a String-RawRepresentable type otherwise gets Swift's default Codable,
// which encodes through rawValue — and rawValue encodes self, so it would recurse forever.
extension Filters {
    private enum CodingKeys: String, CodingKey { case isRiding, bikeKind, hideFullParking, hideEmptyBikes }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isRiding = try c.decode(Bool.self, forKey: .isRiding)
        bikeKind = try c.decode(Need.self, forKey: .bikeKind)
        hideFullParking = try c.decode(Bool.self, forKey: .hideFullParking)
        hideEmptyBikes = try c.decode(Bool.self, forKey: .hideEmptyBikes)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(isRiding, forKey: .isRiding)
        try c.encode(bikeKind, forKey: .bikeKind)
        try c.encode(hideFullParking, forKey: .hideFullParking)
        try c.encode(hideEmptyBikes, forKey: .hideEmptyBikes)
    }
}

// Lets SwiftUI's @AppStorage save Filters as one JSON string.
extension Filters: RawRepresentable {
    public init?(rawValue: String) {
        guard let value = try? JSONDecoder().decode(Filters.self, from: Data(rawValue.utf8)) else { return nil }
        self = value
    }

    public var rawValue: String {
        (try? String(data: JSONEncoder().encode(self), encoding: .utf8)) ?? "{}"
    }
}
