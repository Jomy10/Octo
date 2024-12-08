// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "OctoParseTypes",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "OctoParseTypes",
      type: .dynamic,
      targets: ["OctoParseTypes"]
    )
  ],
  dependencies: [
    .package(path: "../OctoIntermediate")
  ],
  targets: [
    .target(
      name: "OctoParseTypes",
      dependencies: [
        .product(name: "OctoIntermediate", package: "OctoIntermediate")
      ],
      path: "Sources"
    ),
  ]
)
