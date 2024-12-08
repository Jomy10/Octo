import Clang
import OctoIntermediate
import OctoMemory
import OctoConfigKeys

public struct CConfig: Decodable {
  public let clangFlags: [String]
  /// Which headers to include in parsing
  public let includeHeaders: [String]
  /// Which log levels to print
  public let logLevel: ClangDiagnostic
  /// At which level to exit
  public let errorLevel: ClangDiagnostic

  public init(
    clangFlags: [String],
    includeHeaders: [String],
    logLevel: ClangDiagnostic,
    errorLevel: ClangDiagnostic
  ) {
    self.clangFlags = clangFlags
    self.includeHeaders = includeHeaders
    self.logLevel = logLevel
    self.errorLevel = errorLevel
  }

  enum CodingKeys: String, CodingKey {
    case clangFlags = "flags"
    case includeHeaders = "include"
    case logLevel
    case errorLevel
  }

  static var defaultLogLevel: ClangDiagnostic {
    .warning
  }

  static var defaultErrorLevel: ClangDiagnostic {
    .error
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.clangFlags = try container.decodeIfPresent([String].self, forKey: .clangFlags) ?? []
    self.includeHeaders = try container.decodeIfPresent([String].self, forKey: .includeHeaders) ?? []
    self.logLevel = try container.decodeIfPresent(ClangDiagnostic.self, forKey: .logLevel) ?? Self.defaultLogLevel
    self.errorLevel = try container.decodeIfPresent(ClangDiagnostic.self, forKey: .errorLevel) ?? Self.defaultErrorLevel
  }
}

@_cdecl("parseConfigForTOML")
public func parseConfigForTOML(_ containerRawPtr: UnsafeRawPointer, _ output: UnsafeMutablePointer<UnsafeMutableRawPointer?>) -> UnsafeMutableRawPointer? {
  do {
    let containerPtr = containerRawPtr.assumingMemoryBound(to: KeyedDecodingContainer<InputCodingKeys>.self)
    let config = try containerPtr.pointee.decodeIfPresent(CConfig.self, forKey: .langInOpts)
    //let config = CConfig(from: decoderPtr.pointee)
    let rcConfig = Rc(config)
    output.pointee = Unmanaged.passRetained(rcConfig).toOpaque()
    return nil
  } catch let error {
    let errStr = Rc("\(error)")
    return Unmanaged.passRetained(errStr).toOpaque()
  }
}

struct ValidationError: Error {
  let message: String

  init(_ message: String) {
    self.message = message
  }
}

fileprivate func argVal(_ arg: [Substring]) throws -> Substring {
  if arg.count != 2 {
    throw ValidationError("Expected a value for language input option \(arg[0])")
  }
  return arg[1]
}

@_cdecl("parseConfigForArguments")
public func parseConfigForArguments(_ argsPtr: UnsafeRawPointer, out: UnsafeMutablePointer<UnsafeMutableRawPointer?>) -> UnsafeMutableRawPointer? {
  do {
    let args = argsPtr.assumingMemoryBound(to: [[Substring]].self)
    var include: [String] = []
    var clangFlags: [String] = []
    var logLevel: ClangDiagnostic? = nil
    var errorLevel: ClangDiagnostic? = nil

    for arg in args.pointee {
      switch (arg[0]) {
        case "include":
          let val = try argVal(arg)
          include.append(String(val))
        case "clangFlag":
          let val = try argVal(arg)
          clangFlags.append(String(val))
        case "logLevel":
          let val = try argVal(arg)
          logLevel = ClangDiagnostic(fromString: val)
          if logLevel == nil { throw ValidationError("\(val) is not a valid logLevel") }
        case "errorLevel":
          let val = try argVal(arg)
          errorLevel = ClangDiagnostic(fromString: val)
          if errorLevel == nil { throw ValidationError("\(val) is not a valid errorLevel") }
        default:
          throw ValidationError("Option \(arg[0]) is not a known input option for language C")
      }
    }

    let config = Rc(CConfig(
      clangFlags: clangFlags,
      includeHeaders: include,
      logLevel: logLevel ?? CConfig.defaultLogLevel,
      errorLevel: errorLevel ?? CConfig.defaultErrorLevel
    ))
    out.pointee = Unmanaged.passRetained(config).toOpaque()

    return nil
  } catch let error {
    let errStr = Rc("\(error)")
    return Unmanaged.passRetained(errStr).toOpaque()
  }
}
