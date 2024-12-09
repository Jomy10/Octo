import Foundation
import OctoGenerateShared
import OctoIntermediate
import PluginManager

public struct OctoGenerator {
  public static func generate(language: Language, lib: inout OctoLibrary, options: GenerationOptions) throws -> any GeneratedCode {
    try lib.finalize()

    let plugin = try PluginManager.default.getGeneratorPlugin(languageName: language.description)
    let code = try plugin.generate(lib, options)
    return code
  }

  struct LangOptValidationError: Error {
    let message: String

    init(_ message: String) {
      self.message = message
    }
  }

  public static func languageOptions(language: Language, _ args: [[String]]) throws -> UnsafeMutableRawPointer? {
    let subArgs = args.map { $0.map { $0[$0.startIndex..<$0.endIndex] } }
    return try self.languageOptions(language: language, subArgs)
  }

  public static func languageOptions(language: Language, _ args: [[Substring]]) throws -> UnsafeMutableRawPointer? {
    let plugin = try PluginManager.default.getGeneratorPlugin(languageName: language.description)
    var opts: UnsafeMutableRawPointer? = nil
    let error = plugin.parseConfigForArguments(args, &opts)
    if let error = error {
      throw LangOptValidationError(error)
    }
    return opts
  }
}
