// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "OctoMemory",
  products: [
    .library(
      name: "OctoMemory",
      type: .dynamic,
      targets: ["OctoMemory"]
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "OctoMemory",
      dependencies: [],
      path: "Sources"
    ),
  ]
)
