// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RetroDMG",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RetroDMG",
            type: .dynamic,
            targets: ["RetroDMG"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dev-retro/RetroSwift.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RetroDMG", dependencies: [
                .product(name: "RetroSwift", package: "RetroSwift")
            ]),
        .testTarget(
            name: "RetroDMGTests",
            dependencies: ["RetroDMG"]),
    ]
)
