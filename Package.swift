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
    //.library(
    //  name: "Octo",
    //  targets: ["OctoParse", "OctoIntermediate", "OctoGenerate"]
    //),

  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
    .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
    .package(url: "https://github.com/mtynior/ColorizeSwift.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/sushichop/Puppy", from: "0.7.0"),
    .package(url: "https://github.com/apple/swift-system", from: "1.2.1"),
    .package(url: "https://github.com/Jomy10/Plugins.git", branch: "master"),
    .package(path: "SharedLibraries/OctoIntermediate"),
    .package(path: "SharedLibraries/OctoParseTypes"),
    .package(path: "SharedLibraries/OctoConfigKeys"),
    .package(path: "SharedLibraries/OctoMemory"),
    .package(path: "SharedLibraries/OctoIO"),
    //.package(url: "https://github.com/davbeck/swift-glob.git", from: "0.1.0"),
  ],
  targets: [
    .executableTarget(
      name: "OctoCLI",
      dependencies: [
        .product(name: "OctoIO", package: "OctoIo"),
        "ExpressionInterpreter",
        "OctoParse",
        .product(name: "OctoIntermediate", package: "OctoIntermediate"),
        "OctoGenerate",
        "PluginManager",
        .product(name: "OctoConfigKeys", package: "OctoConfigKeys"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "TOMLKit", package: "TOMLKit"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "Puppy", package: "Puppy"),
      ]
    ),

    .target(
      name: "OctoParse",
      dependencies: [
        .product(name: "OctoIntermediate", package: "OctoIntermediate"),
        "ExpressionInterpreter",
        .product(name: "OctoIO", package: "OctoIO"),
        .product(name: "OctoParseTypes", package: "OctoParseTypes"),
        .product(name: "OctoMemory", package: "OctoMemory")
      ]
    ),

    .target(
      name: "OctoGenerate",
      dependencies: [
        .product(name: "OctoIntermediate", package: "OctoIntermediate"),
        .product(name: "OctoIO", package: "OctoIO"),
        "StringBuilder",
      ],
      exclude: ["__c"]
    ),

    .target(
      name: "PluginManager",
      dependencies: [
        .product(name: "Plugins", package: "Plugins")
      ]
    ),

    .target(name: "StringBuilder"),

    .testTarget(
      name: "OctoParseTests",
      dependencies: [
        .product(name: "OctoIntermediate", package: "OctoIntermediate"),
        "OctoParse"
      ]
    ),
    .testTarget(
      name: "OctoGenerateTests",
      dependencies: [
        .product(name: "OctoIntermediate", package: "OctoIntermediate"),
        "OctoGenerate",
        "ColorizeSwift"
      ]
    ),
    .testTarget(
      name: "OctoExecutionTests",
      dependencies: [
        "OctoParse",
        "OctoGenerate",
        .product(name: "OctoIntermediate", package: "OctoIntermediate"),
        "Puppy",
        .product(name: "OctoIO", package: "OctoIO"),
        .product(name: "SystemPackage", package: "swift-system"),
      ],
      exclude: ["resources"]
    )
  ]
)

// XCFramework on macOS, manually static linking on other platforms
#if os(macOS)
package.dependencies.append(
  .package(path: "Sources/ExpressionInterpreter/ExpressionInterpreter")
)
#else
package.targets.append(contentsOf: [
  .systemLibrary(
    name: "ExpressionInterpreterFFI",
    path: "Sources/ExpressionInterpreter/generated"
  ),
  .target(
    name: "ExpressionInterpreter",
    dependencies: ["ExpressionInterpreterFFI"],
    path: "Sources/ExpressionInterpreter/ExpressionInterpreter"
  ),
])
#endif
