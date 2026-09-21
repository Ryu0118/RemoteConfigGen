// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "remote-config-gen",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(name: "remote-config-gen", targets: ["remote-config-gen"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        .package(url: "https://github.com/Ryu0118/FileManagerProtocol", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "remote-config-gen",
            dependencies: [
                "RemoteConfigGenCLI",
                .product(name: "Logging", package: "swift-log"),
            ],
        ),
        .target(
            name: "RemoteConfigGenCLI",
            dependencies: [
                "RemoteConfigGenKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
            ],
        ),
        .target(
            name: "RemoteConfigGenKit",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "FileManagerProtocol", package: "FileManagerProtocol"),
            ],
        ),
        .testTarget(
            name: "RemoteConfigGenKitTests",
            dependencies: ["RemoteConfigGenKit"],
        ),
    ],
)
