// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "OctoIntermediate",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "OctoIntermediate",
      type: .dynamic,
      targets: ["OctoIntermediate"]
    )
  ],
  dependencies: [
    .package(path: "../OctoIO")
  ],
  targets: [
    .target(
      name: "OctoIntermediate",
      dependencies: [
        .product(name: "OctoIO", package: "OctoIO"),
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "OctoIntermediateTests",
      dependencies: ["OctoIntermediate"],
      path: "Tests"
    ),
  ]
)
