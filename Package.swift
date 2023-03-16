// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "STCDataServer",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
                .package(url: "https://github.com/vapor/vapor", .upToNextMajor(from: "4.50.0")),
        .package(url: "https://github.com/orlandos-nl/MongoKitten.git", from: "7.3.0"),
        .package(url: "https://github.com/STCData/SwiftAvroCore.git", branch:"master"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                            "SwiftAvroCore",
                                                        "MongoKitten",

            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of the
                // `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release builds. See
                // <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [
            .target(name: "App"),
        ]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
