import OctoGenerateShared
import OctoConfigKeys
import OctoMemory

public struct CConfig: Decodable {
  /// Prefix types using the library name
  //var prefixTypes: Bool = true
  /// Prefix functions with the library name
  //var prefixFunctions: Bool = true
  /// Prefix functions with the library name if they are attached to a type
  //var prefixFunctionsIfAttached: Bool = false
  /// Prefix functions with the type name of the type the function is attached to
  //var prefixAttachedFunctionsWithType: Bool = true
  /// Use namespaces instead of the prefixed functions when `__cplusplus` is defined
  var useNamespaceInCxx: Bool = true
}

extension GenerationOptions {
  public var cOpts: CConfig {
    let u: Unmanaged<Rc<CConfig>> = Unmanaged.fromOpaque(self.languageSpecificOptions!)
    return u.takeUnretainedValue().takeInner()
  }
}

@_cdecl("parseConfigForTOML")
public func parseConfigForTOML(_ containerRawPtr: UnsafeRawPointer, _ output: UnsafeMutablePointer<UnsafeMutableRawPointer?>) -> UnsafeMutableRawPointer? {
  do {
    let containerPtr = containerRawPtr.assumingMemoryBound(to: KeyedDecodingContainer<OutputCodingKeys>.self)
    let config = try containerPtr.pointee.decodeIfPresent(CConfig.self, forKey: .langOutOpts)
    let rcConfig = Rc(config)
    output.pointee = Unmanaged.passRetained(rcConfig).toOpaque()
    return nil
  } catch let error {
    let errStr = Rc("\(error)")
    return Unmanaged.passRetained(errStr).toOpaque()
  }
}

// TODO: shared
struct ValidationError: Error {
  let message: String

  init(_ message: String) {
    self.message = message
  }
}

// TODO: shared
fileprivate func argVal(_ arg: [Substring]) throws -> Substring {
  if arg.count != 2 {
    throw ValidationError("Expected a value for language input option \(arg[0])")
  }
  return arg[1]
}

fileprivate func argBoolVal(_ arg: [Substring]) throws -> Bool {
  if let val = try? argVal(arg) {
    guard let v = Bool(String(val)) else {
      throw ValidationError("\(arg[1]) is not a valid value for a boolean option \(arg[0])")
    }
    return v
  } else {
    return true
  }
}

@_cdecl("parseConfigForArguments")
public func parseConfigForArguments(_ argsPtr: UnsafeRawPointer, out: UnsafeMutablePointer<UnsafeRawPointer?>) -> UnsafeMutableRawPointer? {
  do {
    let args = argsPtr.assumingMemoryBound(to: [[Substring]].self)
    var config = CConfig()
    for arg in args.pointee {
      if arg.count == 0 {
        throw ValidationError("Malformed argument: No data '\(arg)' in argument list \(args.pointee)")
      }
      switch (arg[0]) {
        //case "prefixTypes":
        //  config.prefixTypes = try argBoolVal(arg)
        //case "prefixFunctions":
        //  config.prefixFunctions = try argBoolVal(arg)
        //case "prefixFunctionsIfAttached":
        //  config.prefixFunctionsIfAttached = try argBoolVal(arg)
        //case "prefixAttachedFunctionsWithType":
        //  config.prefixAttachedFunctionsWithType = try argBoolVal(arg)
        case "useNamespaceInCxx":
          config.useNamespaceInCxx = try argBoolVal(arg)
        default:
          throw ValidationError("Option \(arg[0]) is not a known output option for language C")
      }
    }

    let rcconfig = Rc(config)
    out.pointee = UnsafeRawPointer(Unmanaged.passRetained(rcconfig).toOpaque())

    return nil
  } catch let error {
    let errStr = Rc("\(error)")
    return Unmanaged.passRetained(errStr).toOpaque()
  }
}
