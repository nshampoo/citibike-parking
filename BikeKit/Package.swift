// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BikeKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BikeKit", targets: ["BikeKit"]),
    ],
    targets: [
        .target(name: "BikeKit"),
        .testTarget(name: "BikeKitTests", dependencies: ["BikeKit"]),
    ]
)
