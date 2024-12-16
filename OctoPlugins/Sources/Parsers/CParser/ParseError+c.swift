import Clang
import OctoParseTypes
import OctoIntermediate

extension ParseError {
  static func unhandledKind(_ kind: some CXKind, location: CXSourceLocation? = nil, file: String = #file, function: String = #function, line: Int = #line) -> ParseError {
    let origin: OctoOrigin?
    if let loc = location {
      origin = .c(loc)
    } else {
      origin = nil
    }
    return Self.unhandledKind(kind, origin: origin, file: file, function: function, line: line)
  }

  static func unhandledKind(_ kind: some CXKind, origin: OctoOrigin?, file: String = #file, function: String = #function, line: Int = #line) -> ParseError {
    let msg = "Unhandled \(kind.kindName) (\(kind.rawValue)): \(kind.spelling!) @ \(file) \(function):\(line) (please file a bug report)"
    if let origin = origin {
      return ParseError(msg, origin: origin)
    } else {
      return ParseError(msg)
    }
  }

  static func unhandledToken(_ token: CXToken, translationUnit: CXTranslationUnit, file: String = #file, function: String = #function, line: Int = #line) -> ParseError {
    ParseError("Unhandled token: \(token.spelling(translationUnit: translationUnit)!) @ \(file) \(function):\(line) (please file a bug report)", origin: .c(token.sourceLocation(translationUnit: translationUnit)))
  }
}
