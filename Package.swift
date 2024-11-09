// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Octo",
  platforms: [.macOS(.v13)],
  products: [
    .executable(
      name: "octo",
      targets: ["Octo"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    //.package(url: "https://github.com/davbeck/swift-glob.git", from: "0.1.0"),
  ],
  targets: [
    .executableTarget(
      name: "Octo",
      dependencies: [
        "Clang",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "OctoIO"
        //.product(name: "Glob", package: "swift-glob"),
      ]
    ),
    .target(
      name: "OctoIO"
    ),
    .systemLibrary(
      name: "clang_c",
      providers: [.brew(["llvm"])]
    ),
    .target(
      name: "Clang",
      dependencies: ["clang_c"]
    ),
  ]
)
