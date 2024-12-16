import Foundation
import ExpressionInterpreter
import OctoIntermediate
import OctoParseTypes
import OctoMemory
import PluginManager

public struct OctoParser {
  public static func parse(
    language: Language,
    config: ParseConfiguration,
    input inputURL: URL
  ) throws -> AutoRemoveReference<OctoLibrary> {
    if !(try inputURL.checkResourceIsReachable()) {
      throw InputError.doesntExistOrUnreachable(url: inputURL)
    }

    let parserPlugin = try PluginManager.default.getParserPlugin(languageName: language.description)

    let expectsFile = parserPlugin.parserExpectsFile
    var oisDir: ObjCBool = false
    assert(FileManager.default.fileExists(atPath: inputURL.path, isDirectory: &oisDir))
    let isDir: Bool = oisDir.boolValue
    if expectsFile && isDir {
      throw InputError.isDir(url: inputURL)
    } else if !expectsFile && !isDir {
      throw InputError.isFile(url: inputURL)
    }

    let lib = try parserPlugin.parse(inputURL, config.languageSpecificConfig)
    //var libPtr: UnsafeMutableRawPointer? = nil
    //let error = withUnsafePointer(to: inputURL) { inputURLPtr in
    //  parserPlugin.parse.function(inputURLPtr, config.languageSpecificConfig, &libPtr)
    //  //parseC(input: inputURLPtr, config: config.languageSpecificConfig!, &libPtr)
    //}
    //if let error = error {
    //  let rcerror: Rc<OctoParseTypes.ParseError> = Unmanaged.fromOpaque(error).takeRetainedValue()
    //  throw rcerror.takeInner()
    //}

    //let unmanagedLib: Unmanaged<AutoRemoveReference<OctoLibrary>> = Unmanaged.fromOpaque(libPtr!)
    //let lib: AutoRemoveReference<OctoLibrary> = unmanagedLib.takeRetainedValue()

    let executor = Executor()
    try lib.inner.renameObjects { objName in
      let newName: String = try config.renameOperations.reduce(into: objName, { (currentName: inout String, renameOperation: Program) throws -> () in
        executor.setVar(name: "name", value: .string(value: currentName))
        let newNameValue = try executor.execute(program: renameOperation)
        if case .string(value: let newName) = newNameValue {
          currentName = newName
        } else {
          throw ParseError("while executing rename operation \"\(renameOperation)\": rename operation program doesn't return 'String' (got: \(newNameValue))")
        }
      })
      return newName
    }

    return lib
  }

  struct LangOptValidationError: Error {
    let message: String

    init(_ message: String) {
      self.message = message
    }
  }

  public static func languageOptions(language: Language, _ args: [[String]]) throws -> UnsafeMutableRawPointer? {
    let subArgs = args.map { $0.map { $0[$0.startIndex..<$0.endIndex] } }
    return try self.languageOptions(language: language, subArgs)
  }

  public static func languageOptions(language: Language, _ args: [[Substring]]) throws -> UnsafeMutableRawPointer? {
    let plugin = try PluginManager.default.getParserPlugin(languageName: language.description)
    var opts: UnsafeMutableRawPointer? = nil
    let error = plugin.parseConfigForArguments(args, &opts)
    if let error = error {
      throw LangOptValidationError(error)
    }
    return opts
  }
}

public enum InputError: Error {
  case isDir(url: URL)
  case isFile(url: URL)
  case doesntExistOrUnreachable(url: URL)
}

extension InputError: CustomStringConvertible {
  public var description: String {
    switch (self) {
      case .isDir(url: let url):
        return "InputError: \"\(url.absoluteString)\" is a directory, expected a file"
      case .isFile(url: let url):
        return "InputError: \"\(url.absoluteString)\" is a file, expected a directory"
      case .doesntExistOrUnreachable(url: let url):
        return "InputError: \"\(url.absoluteString)\" doesn't exist or is unreachable"
    }
  }
}
