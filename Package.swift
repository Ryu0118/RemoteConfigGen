// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "RemoteConfigGen",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "RemoteConfigGen", targets: ["RemoteConfigGen"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "RemoteConfigGen",
            dependencies: ["RemoteConfigGenCLI"],
        ),
        .target(
            name: "RemoteConfigGenCLI",
            dependencies: [
                "RemoteConfigGenKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
        ),
        .target(
            name: "RemoteConfigGenKit",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
            ],
        ),
        .testTarget(
            name: "RemoteConfigGenKitTests",
            dependencies: ["RemoteConfigGenKit"],
        ),
    ],
)
