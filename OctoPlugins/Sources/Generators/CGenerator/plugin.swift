import OctoIntermediate
import OctoGenerateShared
import OctoMemory

@_cdecl("outputIsFile")
public func outputIsFile() -> UInt8 {
  return 1
}

@_cdecl("generate")
public func generate(
  _ _lib: UnsafeRawPointer,
  _ _options: UnsafeRawPointer,
  _ out: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) -> UnsafeMutableRawPointer? {
  let lib = _lib.assumingMemoryBound(to: OctoLibrary.self)
  let options = _options.assumingMemoryBound(to: GenerationOptions.self)
  let cOpts = Unmanaged<Rc<CConfig>>.fromOpaque(options.pointee.languageSpecificOptions!).takeRetainedValue() // ensure cleanup at end of this function

  do {
    if lib.pointee.ffiLanguage != .c {
      throw UnsupportedFfiLanguage(lib.pointee.ffiLanguage, supported: [.c])
    }
    let code = try lib.pointee.cGenerate(options: options.pointee)
    let rccode: Rc<any GeneratedCode> = Rc(code)
    out.pointee = Unmanaged.passRetained(rccode).toOpaque()
  } catch let error {
    let rcerr: Rc<any Error> = Rc(error)
    return Unmanaged.passRetained(rcerr).toOpaque()
  }

  _ = cOpts

  return nil
}
