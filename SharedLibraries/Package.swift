// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "OctoSharedLibraries",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "OctoIntermediate",
      type: .dynamic,
      targets: ["OctoIntermediate"]
    ),
    .library(
      name: "OctoParseTypes",
      type: .dynamic,
      targets: ["OctoParseTypes"]
    ),
    .library(
      name: "OctoConfigKeys",
      type: .dynamic,
      targets: ["OctoConfigKeys"]
    ),
    .library(
      name: "Memory",
      type: .dynamic,
      targets: ["Memory"]
    ),
    .library(
      name: "OctoIO",
      type: .dynamic,
      targets: ["OctoIO"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/mtynior/ColorizeSwift.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/sushichop/Puppy", from: "0.7.0"),
  ],
  targets: [
    .target(
      name: "OctoIntermediate",
      dependencies: [
        "OctoIO",
      ]
    ),
    .target(
      name: "OctoParseTypes",
      dependencies: ["OctoIntermediate"]
    ),
    .target(
      name: "OctoConfigKeys"
    ),
    .target( // TODO: AutoRemoveReference + docs
      name: "Memory"
    ),
    .target(
      name: "OctoIO",
      dependencies: [
        "ColorizeSwift",
        "Puppy",
        .product(name: "Logging", package: "swift-log"),
      ]
    ),

    .testTarget(
      name: "OctoIntermediateTests",
      dependencies: ["OctoIntermediate"]
    ),
  ]
)
