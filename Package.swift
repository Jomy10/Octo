// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Octo",
  platforms: [.macOS(.v13)],
  products: [
    .executable(
      name: "octo",
      targets: ["OctoCLI"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
    .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
    //.package(url: "https://github.com/davbeck/swift-glob.git", from: "0.1.0"),
  ],
  targets: [
    .executableTarget(
      name: "OctoCLI",
      dependencies: [
        "Octo",
        "OctoIO",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "TOMLKit", package: "TOMLKit")
      ]
    ),
    .target(
      name: "Octo",
      dependencies: [
        "Clang",
        "OctoIO",
        "ExpressionInterpreter"
        //.product(name: "Glob", package: "swift-glob"),
      ],
      exclude: [
        "generate/README.md",
        "parse/README.md"
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
