import Plugins
import Foundation
import OctoMemory
import OctoIntermediate
import OctoGenerateShared

// This describes the interface a ParserPlugin should have
extension Plugin {
  // TODO: pluginAPIVersion -> determine if Plugin is compatible with current Octo version

  public typealias ParseFunction = @convention(c) (
    UnsafeRawPointer, // input (URL)
    UnsafeRawPointer, // config (Rc<LangConfig?>)
    UnsafeMutablePointer<UnsafeMutableRawPointer?> // output AutoRemoveReference<OctoLibrary>
  ) -> UnsafeMutableRawPointer? // error (any Error)

  /// Indicates whether the parser expects a file or a directory
  public typealias ParserExpectsFileFunction = @convention(c) () -> UInt8

  public typealias GenerateFunction = @convention(c) (
    UnsafeRawPointer, // lib
    UnsafeRawPointer, // options
    UnsafeMutablePointer<UnsafeMutableRawPointer?> // output (Rc<any GeneratedCode>)
  ) -> UnsafeMutableRawPointer? // error

  public typealias GeneratorOutputIsFileFunction = @convention(c) () -> UInt8

  public typealias ConfigParseTOMLFunction = @convention(c) (
    UnsafeRawPointer, // KeyedDecodingContainer<[Input|Output]CodingKeys>
    UnsafeMutablePointer<UnsafeMutableRawPointer?> // output Rc<LangConfig>?
  ) -> UnsafeMutableRawPointer? // error (string)

  public typealias ConfigParseArgumentsFunction = @convention(c) (
    UnsafeRawPointer, // args ([[Substring]])
    UnsafeMutablePointer<UnsafeMutableRawPointer?> // output Rc<LangConfig>?
  ) -> UnsafeMutableRawPointer? // error (string)
}

extension Plugin {
  public var parseFn: PluginFunction<ParseFunction> {
    self.loadFunction(name: "parse")!
  }

  public var parser_expectsFileFn: PluginFunction<ParserExpectsFileFunction> {
    self.loadFunction(name: "expectsFile")!
  }

  public var generateFn: PluginFunction<GenerateFunction> {
    self.loadFunction(name: "generate")!
  }

  public var outputIsFileFn: PluginFunction<GeneratorOutputIsFileFunction> {
    self.loadFunction(name: "outputIsFile")!
  }

  public var parse: (URL, UnsafeMutableRawPointer) throws -> AutoRemoveReference<OctoLibrary> {
    return { (inputURL, config) in
      var libPtr: UnsafeMutableRawPointer? = nil
      let error = withUnsafePointer(to: inputURL) { inputURLPtr in
        self.parseFn.function(inputURLPtr, config, &libPtr)
      }
      if let error = error {
        let rcerror: Rc<any Error> = Unmanaged.fromOpaque(error).takeRetainedValue()
        throw rcerror.takeInner()
      }
      let unmanagedLib: Unmanaged<AutoRemoveReference<OctoLibrary>> = Unmanaged.fromOpaque(libPtr!)
      let lib: AutoRemoveReference<OctoLibrary> = unmanagedLib.takeRetainedValue()
      return lib
    }
  }

  public var parserExpectsFile: Bool {
    self.parser_expectsFileFn.function() == 1
  }

  public var generate: (OctoLibrary, GenerationOptions) throws -> any GeneratedCode {
    return { (lib, options) in
      //let libPtr = Unmanaged.passRetained(lib)
      var out: UnsafeMutableRawPointer? = nil
      let error = withUnsafePointer(to: options) { optionsPtr in
        withUnsafePointer(to: lib) { libPtr in
          self.generateFn.function(UnsafeRawPointer(libPtr), UnsafeRawPointer(optionsPtr), &out)
        }
      }
      if let error = error {
        let rcerror = Unmanaged<Rc<any Error>>.fromOpaque(error).takeRetainedValue()
        throw rcerror.takeInner()
      } else {
        let unmOut: Unmanaged<Rc<any GeneratedCode>> = Unmanaged.fromOpaque(out!)
        let rcout: Rc<any GeneratedCode> = unmOut.takeRetainedValue()
        let out = rcout.takeInner()
        return out
      }
    }
  }

  public var outputIsFile: Bool {
    self.outputIsFileFn.function() == 1
  }

  public var parseConfigForTOMLFn: PluginFunction<ConfigParseTOMLFunction> {
    self.loadFunction(name: "parseConfigForTOML")!
  }

  public var parseConfigForArgumentsFn: PluginFunction<ConfigParseArgumentsFunction> {
    self.loadFunction(name: "parseConfigForArguments")!
  }

  public var parseConfigForTOML: (UnsafeRawPointer, UnsafeMutablePointer<UnsafeMutableRawPointer?>) -> String? {
    return { (container, out) in
      let fn = self.parseConfigForTOMLFn
      let error = fn.function(container, out)

      if let error = error {
        let errorMessage: Rc<String> = Unmanaged.fromOpaque(error).takeRetainedValue()
        return errorMessage.takeInner()
      } else {
        return nil
      }
    }
  }

  public var parseConfigForArguments: ([[Substring]], UnsafeMutablePointer<UnsafeMutableRawPointer?>) -> String? {
    return { (args, out) in
      let fn = self.parseConfigForArgumentsFn
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
