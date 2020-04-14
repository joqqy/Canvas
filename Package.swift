// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Canvas",
    platforms:[.macOS(.v10_11), .iOS(.v10)],
    products: [
        .library(name: "Canvas", targets: ["Canvas"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Canvas", dependencies: []),
        .testTarget(name: "CanvasTests", dependencies: ["Canvas"]),
    ]
)
