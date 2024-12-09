// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "OctoConfigKeys",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "OctoGenerateShared",
      type: .dynamic,
      targets: ["OctoGenerateShared"]
    )
  ],
  dependencies: [
    .package(path: "../OctoIntermediate")
  ],
  targets: [
    .target(
      name: "OctoGenerateShared",
      dependencies: [
        .product(name: "OctoIntermediate", package: "OctoIntermediate"),
      ],
      path: "Sources"
    )
  ]
)
