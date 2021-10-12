// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StatusView",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v11),
    ],
    products: [
        .library(name: "StatusView", targets: ["StatusView"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "StatusView", dependencies: []),
        .testTarget(name: "StatusViewTests", dependencies: ["StatusView"]),
    ]
)
