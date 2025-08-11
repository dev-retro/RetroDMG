// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RetroDMG",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RetroDMG",
            type: .dynamic,
            targets: ["RetroDMG"]),
        .executable(
            name: "RetroDMGApp",
            targets: ["RetroDMGApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dev-retro/RetroKit.git", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-testing.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RetroDMG", dependencies: [
                .product(name: "RetroKit", package: "RetroKit")
            ]),
        .executableTarget(
            name: "RetroDMGApp",
            dependencies: ["RetroDMG"],
            resources: [
                .copy("default.metallib"),
                .process("platforms/macOS/Shaders/Shaders.metal")
            ]
        ),
        .testTarget(
          name: "RetroDMGTests",
          dependencies: [
            "RetroDMG",
            .product(name: "Testing", package: "swift-testing"),
          ],
          resources: [
            .process("CPUTestFiles"),
            .copy("Resources")
          ]
        )
    ]
)
