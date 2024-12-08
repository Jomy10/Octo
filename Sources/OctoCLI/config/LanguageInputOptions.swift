import OctoIntermediate
import ArgumentParser
import OctoParse
import PluginManager
import OctoConfigKeys
import OctoMemory

//protocol LanguageInputOptionSet {}

struct LanguageInputOptions {
  static func decode(
    _ container: KeyedDecodingContainer<InputCodingKeys>,
    language: Language
  ) throws -> UnsafeMutableRawPointer {
    let plugin = try PluginManager.default.getParserPlugin(languageName: language.description)
    var config: UnsafeMutableRawPointer? = nil
    let error = withUnsafePointer(to: container) { containerPtr in
      return plugin.parser_parseConfigForTOML.function(containerPtr, &config)
    }

    if let error = error {
      let errorMessage: Rc<String> = Unmanaged.fromOpaque(error).takeRetainedValue()
      throw ValidationError("\(errorMessage.takeInner())")
    }

    return config!
    //switch (language) {
    //  case .c: return try container.decodeIfPresent(Self.C.self, forKey: .langInOpts)
    //  default: throw ConfigError("Unimplemented input language \(language)")
    //}
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
    let error = withUnsafePointer(to: args) { argsPtr in
      return plugin.parser_parseConfigForArguments.function(UnsafeRawPointer(argsPtr), &config)
    }

    if let error = error {
      let errorMessage: Rc<String> = Unmanaged.fromOpaque(error).takeRetainedValue()
      throw ValidationError("\(errorMessage.takeInner())")
    }

    return config!

    //switch (language) {
    //  //case .c: return try Self.C(fromArguments: args)
    //  default: throw ConfigError("Unimplemented input language \(language)")
    //}
  }

  //typealias C = ParseConfiguration.CConfig
}

fileprivate func argVal(_ arg: [Substring]) throws -> Substring {
  guard let val = arg.get(1) else {
    throw ValidationError("Expected a value for language input option \(arg[0])")
  }
  return val
}

//extension LanguageInputOptions.C: LanguageInputOptionSet {
//  init(fromArguments args: [[Substring]]) throws {
//    var include: [String] = []
//    var clangFlags: [String] = []
//    var logLevel: ClangDiagnostic? = nil
//    var errorLevel: ClangDiagnostic? = nil

//    for arg in args {
//      switch (arg[0]) {
//        case "include":
//        let val = try argVal(arg)
//          include.append(String(val))
//        case "clangFlag":
//          let val = try argVal(arg)
//          clangFlags.append(String(val))
//        case "logLevel":
//          let val = try argVal(arg)
//          logLevel = ClangDiagnostic(fromString: val)
//          if logLevel == nil { throw ValidationError("\(val) is not a valid logLevel") }
//        case "errorLevel":
//          let val = try argVal(arg)
//          errorLevel = ClangDiagnostic(fromString: val)
//          if errorLevel == nil { throw ValidationError("\(val) is not a valid errorLevel") }
//        default:
//          throw ValidationError("Option \(arg[0]) is not a known input option for language C")
//      }
//    }

//    self = .init(
//      clangFlags: clangFlags,
//      includeHeaders: include,
//      logLevel: logLevel ?? .warning,
//      errorLevel: errorLevel ?? .error
//    )
//  }
//}
