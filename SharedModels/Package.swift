// swift-tools-version: 5.10

import PackageDescription

let package: Package = .init(
    name: "SharedModels",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "SharedModels",
            targets: ["SharedModels"]
        ),
    ],
    targets: [
        .target(
            name: "SharedModels",
            dependencies: []
        ),
        .testTarget(
            name: "SharedModelsTests",
            dependencies: ["SharedModels"]
        ),
    ]
)
