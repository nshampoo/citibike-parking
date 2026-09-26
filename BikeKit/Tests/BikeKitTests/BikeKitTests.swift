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

@Test func carriesCoordinates() {
    let s = GBFSClient.merge(info: [info("a", lat: 40.78)], statuses: [status("a")],
                             here: here, count: 3, only: nil)[0]
    #expect(s.coordinate.latitude == 40.78)
    #expect(s.coordinate.longitude == -73.9820)
}

@Test func zeroCapacityBecomesNil() {
    let zero = StationInfo(stationId: "z", name: "Z", lat: 40.78, lon: -73.98, capacity: 0)
    let result = GBFSClient.merge(info: [zero, info("a", lat: 40.781)], statuses: [status("z"), status("a")],
                                  here: here, count: 3, only: nil)
    #expect(result.first { $0.id == "z" }?.capacity == nil)
    #expect(result.first { $0.id == "a" }?.capacity == 20)
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

@Test func mustHaveDockSkipsFullStations() {
    let result = GBFSClient.merge(
        info: [info("full", lat: 40.7782), info("one", lat: 40.779), info("two", lat: 40.78), info("closed", lat: 40.781)],
        statuses: [status("full", docks: 0), status("one", docks: 1), status("two", docks: 2),
                   status("closed", docks: 9, returning: 0)],
        here: here, count: 3, only: nil, mustHave: .dock)
    #expect(result.map(\.id) == ["one", "two"])
}

@Test func slimCacheRoundTrips() throws {
    let original = [info("a", lat: 40.78)]
    let decoded = try JSONDecoder().decode([StationInfo].self, from: JSONEncoder().encode(original))
    #expect(decoded.first?.stationId == "a")
}

@Test func destinationsRoundTrip() throws {
    let work = Destination(name: "Work", latitude: 40.75, longitude: -73.99)
    let decoded = try JSONDecoder().decode([Destination].self, from: JSONEncoder().encode([work]))
    #expect(decoded == [work])
    #expect(decoded[0].location.coordinate.latitude == 40.75)
}

/// Hits the real Citi Bike feed. Run with: LIVE_GBFS=1 swift test
@Test(.enabled(if: ProcessInfo.processInfo.environment["LIVE_GBFS"] != nil))
func liveFeedReturnsNearbyStations() async throws {
    let client = GBFSClient(appGroup: "none", session: .shared)
    let stations = try await client.nearest(to: here)
    #expect(stations.count == 3)
    #expect(stations[0].meters < 1_000)
    print(stations.map { "\($0.name): \($0.docks) docks, \($0.classic)+\($0.ebikes) bikes, \(Int($0.meters))m" })
    let all = try await client.stations(near: here)
    #expect(all.count > 1_000)
}

// MARK: - Short names

@Test(arguments: [
    ("W 72 St & Amsterdam Ave", "72nd"),
    ("Amsterdam Ave & W 73 St", "73rd"),      // street wins even when listed second
    ("4 Ave & 72 St", "72nd"),
    ("W 4 St & 7 Ave S", "4th"),
    ("E 111 St & 1 Ave", "111th"),
    ("W 21 St & 6 Ave", "21st"),
    ("Central Park S & 6 Ave", "6th Av"),     // no numbered street → numbered avenue
    ("67 Ave & Fresh Pond Rd", "67th Av"),
    ("Vesey St & Church St", "Vesey"),        // no numbers → first road, suffix dropped
    ("E Mosholu Pkwy & Van Cortlandt Ave E", "Mosholu"),
    ("Broadway & Roebling St", "Broadway"),
    ("Pier 40 - Hudson River Park", "Pier 40"),
    ("Lafayette Park", "Lafayette Park"),
])
func shortensStationNames(name: String, expected: String) {
    #expect(StationName.short(name) == expected)
}

@Test func ordinals() {
    #expect([1, 2, 3, 4, 11, 12, 13, 22, 101, 112].map(StationName.ordinal)
            == ["1st", "2nd", "3rd", "4th", "11th", "12th", "13th", "22nd", "101st", "112th"])
}

// MARK: - Destinations & commute

@Test func destinationsWithoutKindDecodeAsOther() throws {
    let json = #"[{"id":"6F1C2B8E-8E0A-4C2B-9C8E-0B0D6B4B2A11","name":"Gym","latitude":40.7,"longitude":-73.9}]"#
    let decoded = try JSONDecoder().decode([Destination].self, from: Data(json.utf8))
    #expect(decoded[0].kind == .other)
}

private let nyc: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/New_York")!
    return c
}()

private func at(_ hour: Int, _ minute: Int = 0, day: Int = 24) -> Date {
    nyc.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
}

@Test(arguments: [
    (3, 59, Commute.Leg.toHome),
    (4, 0, .toWork),
    (8, 30, .toWork),
    (11, 59, .toWork),
    (12, 0, .toHome),
    (18, 0, .toHome),
    (23, 30, .toHome),
])
func commuteLegByTime(hour: Int, minute: Int, expected: Commute.Leg) {
    #expect(Commute.leg(at: at(hour, minute), calendar: nyc) == expected)
}

@Test func commuteNextSwitch() {
    #expect(Commute.nextSwitch(after: at(9), calendar: nyc) == at(12))
    #expect(Commute.nextSwitch(after: at(2), calendar: nyc) == at(4))
    #expect(Commute.nextSwitch(after: at(13), calendar: nyc) == at(4, day: 25))
    #expect(Commute.nextSwitch(after: at(12), calendar: nyc) == at(4, day: 25))   // exactly at a switch → the next one
}

// MARK: - Service area

@Test func serviceAreaIsWithin50kmOfAStation() {
    let stations = GBFSClient.merge(info: [info("a", lat: 40.78)], statuses: [status("a")],
                                    here: here, count: 3, only: nil)
    #expect(NearbyStation.serviceArea(stations, contains: here))                                     // Upper West Side
    #expect(NearbyStation.serviceArea(stations, contains: CLLocation(latitude: 40.95, longitude: -73.98)))  // ~19 km north
    #expect(!NearbyStation.serviceArea(stations, contains: CLLocation(latitude: 37.33, longitude: -122.01))) // Cupertino
    #expect(NearbyStation.serviceArea([], contains: CLLocation(latitude: 37.33, longitude: -122.01)))        // not loaded yet
}

// MARK: - Needs (docks vs bikes)

private func station(docks: Int = 4, classic: Int = 3, ebikes: Int = 2, renting: Bool = true) -> NearbyStation {
    NearbyStation(id: "s", name: "S", meters: 0, docks: docks, classic: classic, ebikes: ebikes,
                  renting: renting, latitude: 40.78, longitude: -73.98)
}

@Test func countsEachNeed() {
    let s = station()
    #expect(s.count(of: .dock) == 4)
    #expect(s.count(of: .anyBike) == 5)
    #expect(s.count(of: .eBike) == 2)
    #expect(s.count(of: .classicBike) == 3)
}

@Test func bikesAtANonRentingStationDontCount() {
    let s = station(renting: false)
    #expect(s.count(of: .anyBike) == 0)
    #expect(!s.has(.eBike))
    #expect(s.has(.dock))   // you can still return a bike
}

@Test func mustHaveEBikeFiltersToStationsWithEBikes() {
    let result = GBFSClient.merge(
        info: [info("none", lat: 40.7782), info("some", lat: 40.779)],
        statuses: [status("none", bikes: 4, ebikes: 0), status("some", bikes: 4, ebikes: 1)],
        here: here, count: 3, only: nil, mustHave: .eBike)
    #expect(result.map(\.id) == ["some"])
}

@Test func nounsAreSingularForOne() {
    #expect(Need.dock.noun(for: 1) == "dock")
    #expect(Need.eBike.noun(for: 3) == "e-bikes")
    #expect(Need.anyBike.noun(for: 0) == "bikes")
}

// MARK: - Filters (per-mode memory)

@Test func switchingModesKeepsEachModesFilters() {
    var f = Filters()
    f.hideEmpty = true                 // Park: hide full
    f.isRiding = true
    #expect(f.need == .anyBike)
    #expect(!f.hideEmpty)              // Ride starts with its own setting
    f.toggleBikeKind(.eBike)
    f.hideEmpty = true
    f.isRiding = false
    #expect(f.need == .dock)
    #expect(f.hideEmpty)               // Park's setting came back
    f.isRiding = true
    #expect(f.need == .eBike)          // and Ride's e-bike choice did too
    #expect(f.hideEmpty)
}

@Test func bikeKindTogglesBackToAny() {
    var f = Filters()
    f.isRiding = true
    f.toggleBikeKind(.classicBike)
    #expect(f.need == .classicBike)
    f.toggleBikeKind(.eBike)
    #expect(f.need == .eBike)          // switching kinds replaces, never both
    f.toggleBikeKind(.eBike)
    #expect(f.need == .anyBike)
    f.toggleBikeKind(.dock)            // not a bike kind: ignored
    #expect(f.need == .anyBike)
}

@Test func filtersSurviveBeingSaved() {
    var f = Filters()
    f.isRiding = true
    f.toggleBikeKind(.eBike)
    f.hideFullParking = true
    #expect(Filters(rawValue: f.rawValue) == f)
    #expect(Filters(rawValue: "not json") == nil)
}
