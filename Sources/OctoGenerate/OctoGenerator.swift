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
}
