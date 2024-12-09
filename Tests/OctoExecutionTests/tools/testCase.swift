import Foundation
import XCTest
import OctoIO
import OctoParse
import OctoGenerate
import OctoGenerateShared
import SystemPackage
import PluginManager

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

struct TestError: Error {
  let message: String
}

fileprivate func intoSubstringArray(_ arr: [[String]]) -> [[Substring]] {
  arr.map { innerArr in
    innerArr.map { inner in
      inner[inner.startIndex..<inner.endIndex]
    }
  }
}

fileprivate func loadCParseConfig() throws -> ParseConfiguration {
  let plugin = try PluginManager.default.getParserPlugin(languageName: "C")
  let args = [
    ["logLevel", "ignored"],
    ["errorLevel", "warning"]
  ]

  var langConfig: UnsafeMutableRawPointer? = nil
  let errorMessage = plugin.parser_parseConfigForArguments(intoSubstringArray(args), &langConfig)
  if let errorMessage = errorMessage {
    throw TestError(message: errorMessage)
  }

  return ParseConfiguration(
    languageSpecificConfig: langConfig!,
    renameOperations: []
  )
}

/// C -> Ruby
func execRubyTestCase(
  libname: String,
  name: String
) throws {
  try XCTSkipIf(Tools.clang == nil, "C compiler not found")
  try XCTSkipIf(Tools.ruby == nil, "Ruby not found")

  let config = try loadCParseConfig()
  //let config = ParseConfiguration(
  //  languageSpecificConfig: .c(ParseConfiguration.CConfig(
  //    clangFlags: [],
  //    includeHeaders: [],
  //    logLevel: .note,
  //    errorLevel: .warning
  //  )),
  //  renameOperations: []
  //)

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
    lib: &lib.inner,
    options: rubyGenOptions
  )

  try code.write(to: outFile("\(name).rb"))

  let (stdout, stderr) = try executeData(Tools.ruby!, [testFile("\(name)/\(name)_main.rb").path], extraLibPath: outFile("").path)
  if stderr.count != 0 {
    print(String(data: stderr, encoding: .utf8)!, to: .stderr)
  }
  let tester = try Tester(json: stdout)

  for assertion in tester.assertions {
    XCTAssert(assertion.success, assertion.msgOnError + " @ " + assertion.path + ":" + String(assertion.line))
  }
}
