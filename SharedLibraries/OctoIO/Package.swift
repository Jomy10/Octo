// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "OctoIO",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "OctoIO",
      type: .dynamic,
      targets: ["OctoIO"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/mtynior/ColorizeSwift.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/sushichop/Puppy", from: "0.7.0"),
  ],
  targets: [
    .target(
      name: "OctoIO",
      dependencies: [
        "ColorizeSwift",
        "Puppy",
        .product(name: "Logging", package: "swift-log"),
      ],
      path: "Sources"
    ),
  ]
)
