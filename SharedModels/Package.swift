// swift-tools-version: 5.10

import PackageDescription

let package: Package = Package(
  name: "SharedModels",
  platforms: [.iOS(.v17)],
  products: [
    .library(
      name: "SharedModels",
      targets: ["SharedModels"])
  ],
  targets: [
    .target(
      name: "SharedModels",
      dependencies: [])
  ]
)
