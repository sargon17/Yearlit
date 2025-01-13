// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedModels",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "SharedModels",
            targets: ["SharedModels"]),
    ],
    targets: [
        .target(
            name: "SharedModels",
            dependencies: [])
    ]
) 