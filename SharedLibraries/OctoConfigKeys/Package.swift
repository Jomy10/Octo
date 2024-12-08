// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "OctoConfigKeys",
  products: [
    .library(
      name: "OctoConfigKeys",
      type: .dynamic,
      targets: ["OctoConfigKeys"]
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "OctoConfigKeys",
      dependencies: [],
      path: "Sources"
    ),
  ]
)
