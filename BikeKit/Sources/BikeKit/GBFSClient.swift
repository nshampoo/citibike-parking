import Foundation
import CoreLocation

public enum GBFSError: Error {
    case badResponse(Int)
}

/// Fetches Citi Bike GBFS feeds. Station info is cached in the App Group
/// for 24 hours; status is always fetched fresh.
public actor GBFSClient {
    public static let shared = GBFSClient(appGroup: AppGroup.id)

    private let base = URL(string: "https://gbfs.lyft.com/gbfs/1.1/bkn/en/")!
    private let cacheURL: URL
    private let session: URLSession
    private let feedDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    public init(appGroup: String, session: URLSession = .shared) {
        // containerURL is nil if the App Group entitlement is missing (e.g. an
        // unsigned build) — fall back to Caches rather than crashing.
        let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheURL = dir.appendingPathComponent("stations-v1.json")
        self.session = session
    }

    // MARK: Public API

    /// Every station (id, name, location), sorted by name — for search.
    public func allStations() async throws -> [StationSummary] {
        try await stationInfo()
            .map { StationSummary(id: $0.stationId, name: $0.name, latitude: $0.lat, longitude: $0.lon) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The `count` closest installed stations, optionally limited to `only` IDs.
    public func nearest(to here: CLLocation, count: Int = 3, only: Set<String>? = nil) async throws -> [NearbyStation] {
        async let info = stationInfo()
        async let statuses = stationStatus()
        return try await Self.merge(info: info, statuses: statuses, here: here, count: count, only: only)
    }

    // MARK: Pure logic (unit-tested)

    static func merge(info: [StationInfo], statuses: [StationStatus], here: CLLocation,
                      count: Int, only: Set<String>?) -> [NearbyStation] {
        let byId = Dictionary(statuses.map { ($0.stationId, $0) }, uniquingKeysWith: { a, _ in a })
        return info
            .compactMap { s -> NearbyStation? in
                guard let st = byId[s.stationId], st.isInstalled == 1,
                      only?.contains(s.stationId) ?? true else { return nil }
                let e = st.numEbikesAvailable ?? 0
                return NearbyStation(
                    id: s.stationId, name: s.name,
                    meters: here.distance(from: CLLocation(latitude: s.lat, longitude: s.lon)),
                    docks: st.isReturning == 1 ? st.numDocksAvailable : 0,
                    classic: max(0, st.numBikesAvailable - e), ebikes: e,
                    renting: st.isRenting == 1,
                    capacity: (s.capacity ?? 0) > 0 ? s.capacity : nil)
            }
            .sorted { $0.meters < $1.meters }
            .prefix(count)
            .map { $0 }
    }

    // MARK: Networking + cache

    private func stationInfo() async throws -> [StationInfo] {
        if let mod = try? cacheURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
           Date().timeIntervalSince(mod) < 86_400,
           let cached = try? Data(contentsOf: cacheURL),
           let stations = try? JSONDecoder().decode([StationInfo].self, from: cached) {
            return stations
        }
        let data = try await fetch("station_information.json", cachePolicy: .useProtocolCachePolicy)
        // Decode first so a bad download never gets cached.
        let stations = try feedDecoder.decode(GBFS<InfoData>.self, from: data).data.stations
        try? JSONEncoder().encode(stations).write(to: cacheURL, options: .atomic)
        return stations
    }

    private func stationStatus() async throws -> [StationStatus] {
        // Bypass URLCache so the refresh button always gets live numbers.
        let data = try await fetch("station_status.json", cachePolicy: .reloadIgnoringLocalCacheData)
        return try feedDecoder.decode(GBFS<StatusData>.self, from: data).data.stations
    }

    private func fetch(_ file: String, cachePolicy: URLRequest.CachePolicy) async throws -> Data {
        let request = URLRequest(url: base.appendingPathComponent(file), cachePolicy: cachePolicy, timeoutInterval: 15)
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw GBFSError.badResponse(http.statusCode)
        }
        return data
    }
}
