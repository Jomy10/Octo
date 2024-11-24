import Foundation
import ArgumentParser
import OctoIntermediate

/// CLI Arguments
struct OctoManualArguments: ParsableArguments {
  // Input (parse) options //

  @Option(name: .customLong("from"), help: "The input language to create bindings from (required)")
  var inputLanguage: Language? = nil

  @Option(name: [.short, .customLong("input-location")], help: "Input path (required)")
  var inputLocation: URL? = nil

  @Option(name: [.customShort("I"), .customLong("lang-in-opt")], help: "Specify a language specific option for the language being parsed (format: <optname>[=value])")
  var langInOpts: [String] = []

  @Option(name: [.short, .customLong("attribute")], help: "Apply an attribute to a symbol, format: [symbol]>[attributeName]{=argList,}")
  var attributes: [Attribute] = []

  // Output (generation) options //

  @Option(name: .customLong("to"), help: "The output language to create bindings for (required)")
  var outputLanguage: Language? = nil

  @Option(name: [.short, .customLong("output")], help: "Output path (required)")
  var outputLocation: URL? = nil

  @Option(name: [.customShort("O"), .customLong("lang-out-opt")], help: "Specify a language specific option for the language for which bindings are generated for (format: <optname>[=value])")
  var langOutOpts: [String] = []

  @Option(name: [.customShort("n"), .customLong("lib-name")], help: "The name of the library to be generated (required)")
  var outputLibraryName: String? = nil

  @Option(name: .shortAndLong, help: "The library/libraries to link against in the output")
  var link: [String] = []

  @Option(name: .long, help: "`tabs` or `spaces`")
  var indentType: IndentType? = nil

  @Option(name: .long, help: "The amount of --indent-type to indent")
  var indentCount: Int? = nil
}

struct OctoConfigFileArguments: ParsableArguments {
  @Option(name: [.short, .customLong("config")], help: "The path to the config file in TOML format")
  var configFile: URL? = nil
}
