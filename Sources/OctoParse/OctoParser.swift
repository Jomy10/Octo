import Foundation
import ExpressionInterpreter
import OctoIntermediate

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

public struct OctoParser {
  public static func parse(
    language: Language,
    config: ParseConfiguration,
    input inputURL: URL
  ) throws -> AutoRemoveReference<OctoLibrary> {
    if !(try inputURL.checkResourceIsReachable()) {
      throw InputError.doesntExistOrUnreachable(url: inputURL)
    }

    let executor = Executor()
    var lib: AutoRemoveReference<OctoLibrary>
    switch (language) {
      case .c:
        lib = try Self.parseC(input: inputURL, config: config)
      default:
        throw ParseError("Unimplemented language \(language)")
    }

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
}
