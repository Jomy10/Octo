// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Octo",
  platforms: [.macOS(.v13)],
  products: [
    .executable(
      name: "octo",
      targets: ["OctoCLI"]
    ),
    .library(
      name: "Octo",
      targets: ["OctoParse", "OctoIntermediate", "OctoGenerate"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
    .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
    .package(url: "https://github.com/mtynior/ColorizeSwift.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/sushichop/Puppy", from: "0.7.0"),
    .package(url: "https://github.com/apple/swift-system", from: "1.2.1"),
    //.package(url: "https://github.com/davbeck/swift-glob.git", from: "0.1.0"),
  ],
  targets: [
    .executableTarget(
      name: "OctoCLI",
      dependencies: [
        "OctoIO",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "TOMLKit", package: "TOMLKit"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "Puppy", package: "Puppy")
      ]
    ),

    .target(
      name: "OctoIntermediate",
      dependencies: [
        "OctoIO",
        "ExpressionInterpreter"
      ]
    ),
    .target(
      name: "OctoParse",
      dependencies: [
        "Clang",
        "OctoIntermediate",
        "OctoIO"
      ]
    ),
    .target(
      name: "OctoGenerate",
      dependencies: [
        "OctoIntermediate",
        "OctoIO",
        "StringBuilder"
      ]
    ),

    .target(
      name: "OctoIO",
      dependencies: [
        "ColorizeSwift",
        "Puppy",
        .product(name: "Logging", package: "swift-log"),
      ]
    ),

    .target(name: "StringBuilder"),

    //.target(
    //  name: "SwiftSystem",
    //  dependencies: [
    //    .product(name: "SystemPackage", package: "swift-system"),
    //  ]
    //),

    .systemLibrary(
      name: "clang_c",
      providers: [
        .brew(["llvm"]),
        .apt(["clang", "llvm-dev"])
      ]
    ),
    .target(
      name: "Clang",
      dependencies: ["clang_c"]
    ),

    .testTarget(
      name: "OctoIntermediateTests",
      dependencies: ["OctoIntermediate"]
    ),
    .testTarget(
      name: "OctoParseTests",
      dependencies: ["OctoIntermediate", "OctoParse"]
    ),
    .testTarget(
      name: "OctoGenerateTests",
      dependencies: ["OctoIntermediate", "OctoGenerate", "ColorizeSwift"]
    ),
    .testTarget(
      name: "OctoExecutionTests",
      dependencies: [
        "OctoParse",
        "OctoGenerate",
        "OctoIntermediate",
        "Puppy",
        "OctoIO",
        .product(name: "SystemPackage", package: "swift-system"),
      ],
      exclude: ["resources"]
    )
  ]
)

// XCFramework on macOS, manually static linking on other platforms
#if os(macOS)
package.dependencies.append(
  .package(path: "ExpressionInterpreter/ExpressionInterpreter")
)
#else
package.targets.append(contentsOf: [
  .systemLibrary(
    name: "ExpressionInterpreterFFI",
    path: "ExpressionInterpreter/generated"
  ),
  .target(
    name: "ExpressionInterpreter",
    dependencies: ["ExpressionInterpreterFFI"],
    path: "ExpressionInterpreter/ExpressionInterpreter"
  ),
])
#endif
