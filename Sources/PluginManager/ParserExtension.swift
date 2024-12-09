import Plugins
import OctoMemory

// This describes the interface a ParserPlugin should have
extension Plugin {
  // TODO: pluginAPIVersion -> determine if Plugin is compatible with current Octo version

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

  public var parser_parseConfigForArgumentsFn: PluginFunction<ConfigParseArgumentsFunction> {
    self.loadFunction(name: "parseConfigForArguments")!
  }

  public var parser_expectsFile: PluginFunction<ParserExpectsFileFunction> {
    self.loadFunction(name: "expectsFile")!
  }

  // TODO: binding

  public var parser_parseConfigForArguments: ([[Substring]], UnsafeMutablePointer<UnsafeMutableRawPointer?>) -> String? {
    return { (args, out) in
      let fn = self.parser_parseConfigForArgumentsFn
      let error = withUnsafePointer(to: args) { argsPtr in
        fn.function(argsPtr, out)
      }
      if let error = error {
        let errorMessage: Rc<String> = Unmanaged.fromOpaque(error).takeRetainedValue()
        return errorMessage.takeInner()
      } else {
        return nil
      }
    }
  }
}
