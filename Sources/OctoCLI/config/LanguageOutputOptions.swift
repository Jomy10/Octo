import OctoIntermediate
import PluginManager
import OctoConfigKeys
import OctoMemory
import ArgumentParser

struct LanguageOutputOptions {
  static func decode(
    _ container: KeyedDecodingContainer<OutputCodingKeys>,
    language: Language
  ) throws -> UnsafeMutableRawPointer? {
    let plugin = try PluginManager.default.getGeneratorPlugin(languageName: language.description)
    var config: UnsafeMutableRawPointer? = nil
    let error = withUnsafePointer(to: container) { containerPtr in
      return plugin.parseConfigForTOML(containerPtr, &config)
    }

    if let error = error {
      throw ValidationError(error)
    }

    return config
  }

  static func parse(
    arguments args: [String],
    language: Language
  ) throws -> UnsafeMutableRawPointer? {
    let args = args.map { arg in
      arg.split(separator: "=")
    }

    let plugin = try PluginManager.default.getGeneratorPlugin(languageName: language.description)
    var config: UnsafeMutableRawPointer? = nil
    let errorMessage = plugin.parseConfigForArguments(args, &config)

    if let errorMessage = errorMessage {
      throw ValidationError(errorMessage)
    }

    return config
  }
}
