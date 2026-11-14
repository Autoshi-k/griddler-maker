// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GriddlerMaker",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure image-processing + puzzle logic, no UI. Unit tested.
        .target(name: "GriddlerCore"),
        // SwiftUI macOS app.
        .executableTarget(name: "GriddlerMaker", dependencies: ["GriddlerCore"]),
        .testTarget(name: "GriddlerCoreTests", dependencies: ["GriddlerCore"]),
    ]
)
