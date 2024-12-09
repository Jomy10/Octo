import Plugins
import OctoMemory
import OctoIntermediate
import OctoGenerateShared

extension Plugin {
  public typealias GenerateFunction = @convention(c) (
    UnsafeRawPointer, // lib
    UnsafeRawPointer, // options
    UnsafeMutablePointer<UnsafeMutableRawPointer?> // output (Rc<any GeneratedCode>)
  ) -> UnsafeMutableRawPointer? // error

  public typealias GeneratorOutputIsFileFunction = @convention(c) () -> UInt8
}

extension Plugin {
  public var generateFn: PluginFunction<GenerateFunction> {
    self.loadFunction(name: "generate")!
  }

  public var outputIsFileFn: PluginFunction<GeneratorOutputIsFileFunction> {
    self.loadFunction(name: "outputIsFile")!
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
}
