import Testing
import Foundation
import CoreLocation
@testable import BikeKit

private let here = CLLocation(latitude: 40.7781, longitude: -73.9820)

private func info(_ id: String, lat: Double) -> StationInfo {
    StationInfo(stationId: id, name: "Station \(id)", lat: lat, lon: -73.9820, capacity: 20)
}

private func status(_ id: String, bikes: Int = 5, ebikes: Int? = 2, docks: Int = 10,
                    installed: Int = 1, renting: Int = 1, returning: Int = 1) -> StationStatus {
    StationStatus(stationId: id, numBikesAvailable: bikes, numEbikesAvailable: ebikes, numDocksAvailable: docks,
                  isInstalled: installed, isRenting: renting, isReturning: returning)
}

@Test func decodesRealFeedShape() throws {
    let json = """
    {"data":{"stations":[{"station_id":"abc","num_bikes_available":7,"num_ebikes_available":3,
      "num_docks_available":12,"is_installed":1,"is_renting":1,"is_returning":0,"extra":"ignored"}]}}
    """.data(using: .utf8)!
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase
    let s = try d.decode(GBFS<StatusData>.self, from: json).data.stations[0]
    #expect(s.stationId == "abc")
    #expect(s.numEbikesAvailable == 3)
    #expect(s.isReturning == 0)
}

@Test func sortsByDistanceAndLimitsCount() {
    let result = GBFSClient.merge(
        info: [info("far", lat: 40.80), info("near", lat: 40.779), info("mid", lat: 40.785)],
        statuses: [status("far"), status("near"), status("mid")],
        here: here, count: 2, only: nil)
    #expect(result.map(\.id) == ["near", "mid"])
}

@Test func splitsClassicAndEbikes() {
    let s = GBFSClient.merge(info: [info("a", lat: 40.78)], statuses: [status("a", bikes: 5, ebikes: 2)],
                             here: here, count: 3, only: nil)[0]
    #expect(s.classic == 3)
    #expect(s.ebikes == 2)
}

@Test func notReturningMeansZeroDocks() {
    let s = GBFSClient.merge(info: [info("a", lat: 40.78)], statuses: [status("a", docks: 9, returning: 0)],
                             here: here, count: 3, only: nil)[0]
    #expect(s.docks == 0)
}

@Test func skipsUninstalledAndUnknownStations() {
    let result = GBFSClient.merge(
        info: [info("gone", lat: 40.78), info("ok", lat: 40.79), info("nostatus", lat: 40.779)],
        statuses: [status("gone", installed: 0), status("ok")],
        here: here, count: 3, only: nil)
    #expect(result.map(\.id) == ["ok"])
}

@Test func filtersToFavorites() {
    let result = GBFSClient.merge(
        info: [info("a", lat: 40.78), info("b", lat: 40.79), info("c", lat: 40.80)],
        statuses: [status("a"), status("b"), status("c")],
        here: here, count: 6, only: ["c", "a"])
    #expect(result.map(\.id) == ["a", "c"])
}

@Test func slimCacheRoundTrips() throws {
    let original = [info("a", lat: 40.78)]
    let decoded = try JSONDecoder().decode([StationInfo].self, from: JSONEncoder().encode(original))
    #expect(decoded.first?.stationId == "a")
}

/// Hits the real Citi Bike feed. Run with: LIVE_GBFS=1 swift test
@Test(.enabled(if: ProcessInfo.processInfo.environment["LIVE_GBFS"] != nil))
func liveFeedReturnsNearbyStations() async throws {
    let client = GBFSClient(appGroup: "none", session: .shared)
    let stations = try await client.nearest(to: here)
    #expect(stations.count == 3)
    #expect(stations[0].meters < 1_000)
    print(stations.map { "\($0.name): \($0.docks) docks, \($0.classic)+\($0.ebikes) bikes, \(Int($0.meters))m" })
    let all = try await client.allStations()
    #expect(all.count > 1_000)
}
