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
  //let out = _out.assumingMemoryBound(to: Rc<any GeneratedCode>.self)
  //let libUnmanaged: Unmanaged<AutoRemoveReference<OctoLibrary>> = Unmanaged.fromOpaque(_lib)
  //let lib = libUnmanaged.takeRetained()

  do {
    let code = try lib.pointee.rubyGenerate(options: options.pointee)
    let rccode: Rc<any GeneratedCode> = Rc(code)
    out.pointee = Unmanaged.passRetained(rccode).toOpaque()
  } catch let error {
    let rcerr = Rc(error)
    return Unmanaged.passRetained(rcerr).toOpaque()
  }

  return nil
}
