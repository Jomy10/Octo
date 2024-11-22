import Clang

extension ParseError {
  static func unhandledKind(_ kind: some CXKind, location: CXSourceLocation? = nil, file: String = #file, function: String = #function, line: Int = #line) -> ParseError {
    let msg = "Unhandled \(kind.kindName) (\(kind.rawValue)): \(kind.spelling!) @ \(file) \(function):\(line) (please file a bug report)"
    if let location = location {
      return ParseError(msg, origin: .c(location))
    } else {
      return ParseError(msg)
    }
  }

  static func unhandledToken(_ token: CXToken, translationUnit: CXTranslationUnit, file: String = #file, function: String = #function, line: Int = #line) -> ParseError {
    ParseError("Unhandled token: \(token.spelling(translationUnit: translationUnit)!) @ \(file) \(function):\(line) (please file a bug report)", origin: .c(token.sourceLocation(translationUnit: translationUnit)))
  }
}
