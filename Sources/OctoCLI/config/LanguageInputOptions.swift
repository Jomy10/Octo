import OctoIntermediate
import ArgumentParser
import OctoParse
import PluginManager
import OctoConfigKeys
import OctoMemory

struct LanguageInputOptions {
  static func decode(
    _ container: KeyedDecodingContainer<InputCodingKeys>,
    language: Language
  ) throws -> UnsafeMutableRawPointer {
    let plugin = try PluginManager.default.getParserPlugin(languageName: language.description)
    var config: UnsafeMutableRawPointer? = nil
    let error = withUnsafePointer(to: container) { containerPtr in
      return plugin.parseConfigForTOML(containerPtr, &config)
    }

    if let error = error {
      throw ValidationError(error)
    }

    return config!
  }

  static func parse(
    arguments args: [String],
    language: Language
  ) throws -> UnsafeMutableRawPointer {
    let args = args.map { arg in
      arg.split(separator: "=")
    }

    let plugin = try PluginManager.default.getParserPlugin(languageName: language.description)
    var config: UnsafeMutableRawPointer? = nil
    let errorMessage = plugin.parseConfigForArguments(args, &config)

    if let errorMessage = errorMessage {
      throw ValidationError(errorMessage)
    }

    return config!
  }
}
