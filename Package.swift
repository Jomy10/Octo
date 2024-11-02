// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Brooklyn",
  platforms: [.macOS(.v13)],
  products: [
    .executable(
      name: "Brooklyn",
      targets: ["Brooklyn"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    //.package(url: "https://github.com/davbeck/swift-glob.git", from: "0.1.0"),
  ],
  targets: [
    .executableTarget(
      name: "Brooklyn",
      dependencies: [
        "Clang",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        //.product(name: "Glob", package: "swift-glob"),
      ]
    ),
    .systemLibrary(
      name: "clang_c"
    ),
    .target(
      name: "Clang",
      dependencies: ["clang_c"]
    ),
  ]
)
