import Plugins

// This describes the interface a ParserPlugin should have
extension Plugin {
  public typealias ParseFunction = @convention(c) (
    UnsafeRawPointer, // input (URL)
    UnsafeRawPointer, // config (Rc<LangConfig?>)
    UnsafeMutablePointer<UnsafeMutableRawPointer?> // output AutoRemoveReference<OctoLibrary>
  ) -> UnsafeMutableRawPointer? // error (ParseError)

  public typealias ConfigParseTOMLFunction = @convention(c) (
    UnsafeRawPointer, // KeyedDecodingContainer<InputCodingKeys>
    UnsafeMutablePointer<UnsafeMutableRawPointer?> // output Rc<LangConfig>
  ) -> UnsafeMutableRawPointer? // error (string)

  public typealias ConfigParseArgumentsFunction = @convention(c) (
    UnsafeRawPointer, // args ([[Substring]])
    UnsafeMutablePointer<UnsafeMutableRawPointer?> // output Rc<LangConfig>
  ) -> UnsafeMutableRawPointer? // error (string)

  /// Indicates whether the parser expects a file or a directory
  public typealias ParserExpectsFileFunction = @convention(c) () -> UInt8
}

extension Plugin {
  public var parse: PluginFunction<ParseFunction> {
    self.loadFunction(name: "parse")!
  }

  public var parser_parseConfigForTOML: PluginFunction<ConfigParseTOMLFunction> {
    self.loadFunction(name: "parseConfigForTOML")!
  }

  public var parser_parseConfigForArguments: PluginFunction<ConfigParseArgumentsFunction> {
    self.loadFunction(name: "parseConfigForArguments")!
  }

  public var parser_expectsFile: PluginFunction<ParserExpectsFileFunction> {
    self.loadFunction(name: "expectsFile")!
  }
}
