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
    targets: [
        .executableTarget(
            name: "RemoteConfigGen",
            dependencies: ["RemoteConfigGenKit"]
        ),
        .target(name: "RemoteConfigGenKit"),
        .testTarget(
            name: "RemoteConfigGenKitTests",
            dependencies: ["RemoteConfigGenKit"]
        ),
    ]
)
