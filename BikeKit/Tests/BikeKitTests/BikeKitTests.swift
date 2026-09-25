import Testing
@testable import BikeKit

@Test func appGroupHasFallback() {
    #expect(!AppGroup.id.isEmpty)
}
