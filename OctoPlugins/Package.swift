// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "OctoPlugins",
  platforms: [.macOS(.v13)],
  products: [
    .library(
      name: "CParser",
      type: .dynamic,
      targets: ["CParser"]
    )
  ],
  dependencies: [
    .package(path: "../SharedLibraries/OctoIntermediate"),
    .package(path: "../SharedLibraries/OctoParseTypes"),
    .package(path: "../SharedLibraries/OctoConfigKeys"),
    .package(path: "../SharedLibraries/OctoMemory"),
    .package(path: "../SharedLibraries/OctoIO"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "CParser",
      dependencies: [
        .product(name: "OctoIntermediate", package: "OctoIntermediate"),
        .product(name: "OctoParseTypes", package: "OctoParseTypes"),
        .product(name: "OctoConfigKeys", package: "OctoConfigKeys"),
        .product(name: "OctoMemory", package: "OctoMemory"),
        .product(name: "OctoIO", package: "OctoIO"),
        .product(name: "Logging", package: "swift-log"),
        "Clang"
      ],
      path: "Sources/Parsers/CParser"
    ),
    .systemLibrary(
      name: "clang_c",
      path: "Sources/Clang/clang_c",
      providers: [
        .brew(["llvm"]),
        .apt(["clang", "llvm-dev"]),
      ]
    ),
    .target(
      name: "Clang",
      dependencies: ["clang_c"],
      path: "Sources/Clang/Clang"
    ),
  ]
)
