import Foundation
import XCTest
import OctoParse
import OctoGenerate
import SwiftSystem

func setup(name: String) throws {
  // Tests output directory
  try FileManager.default.createDirectory(
    atPath: "./.build/tests/",
    withIntermediateDirectories: true,
    attributes: nil
  )

  // Compile adder
  if let clang = Tools.clang {
    #if os(macOS)
    let libType = "-dynamiclib"
    let outLib = outFile("lib\(name).dylib")
    #else
    let libType = "-shared"
    let outLib = outFile("lib\(name).so")
    #endif
    try execute(clang, [testFile("\(name)/\(name).c").path, "-fPIC", libType, "-o", outLib.path])
    let outLibPath = FilePath(stringLiteral: outLib.path)
    try outLibPath.chmod([.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute])
  }
}

func execRubyTestCase(
  libname: String,
  name: String
) throws {
  try XCTSkipIf(Tools.clang == nil, "C compiler not found")
  try XCTSkipIf(Tools.ruby == nil, "Ruby not found")

  let config = ParseConfiguration(
    outputLibraryName: libname,
    languageSpecificConfig: .c(ParseConfiguration.CConfig(
      clangFlags: [],
      includeHeaders: [],
      logLevel: .note,
      errorLevel: .warning
    )),
    renameOperations: []
  )

  let rubyGenOptions = GenerationOptions(
    moduleName: libname,
    indent: "  ",
    libs: [name]
  )

  let lib = try OctoParser.parse(
    language: .c,
    config: config,
    input: testFile("\(name)/\(name).h")
  )

  let code = try OctoGenerator.generate(
    language: .ruby,
    lib: lib.inner,
    options: rubyGenOptions
  )

  try code.write(to: outFile("\(name).rb"))

  let (stdout, _) = try executeData(Tools.ruby!, [testFile("\(name)/\(name)_main.rb").path], extraLibPath: outFile("").path)
  let tester = try Tester(json: stdout)

  for assertion in tester.assertions {
    XCTAssert(assertion.success, assertion.msgOnError + " @ " + assertion.path)
  }
}
