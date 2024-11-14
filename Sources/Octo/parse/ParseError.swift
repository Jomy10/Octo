import Foundation
import Clang

struct ParseError: Error, CustomStringConvertible {
  let origin: OctoOrigin?
  let message: String

  init(_ message: String) {
    self.message = message
    self.origin = nil
  }

  init(
    _ message: String,
    _ origin: OctoOrigin? = nil
  ) {
    self.origin = origin
    self.message = message
  }

  init(
    _ message: String,
    _ origin: CXSourceLocation? = nil
  ) {
    if let origin = origin {
      self.origin = .init(c: origin)
    } else {
      self.origin = nil
    }
    self.message = message
  }

  var description: String {
    var prefix = ""
    if let origin = self.origin {
       prefix += "\(URL(fileURLWithPath: origin.file).relativePath): "
    }
    return "\(prefix)[ERROR] \(message)"
  }

  static func unhandledKind(_ kind: some CXKind, location: CXSourceLocation? = nil, file: String = #file, function: String = #function, line: Int = #line) -> ParseError {
    let msg = "Unhandled \(kind.kindName) (\(kind.rawValue)): \(kind.spelling!) @ \(file) \(function):\(line)"
    if let location = location {
      return ParseError(msg, location)
    } else {
      return ParseError(msg, location)
    }
  }

  static func unhandledToken(_ token: CXToken, translationUnit: CXTranslationUnit, file: String = #file, function: String = #function, line: Int = #line) -> ParseError {
    ParseError("Unhandled token: \(token.spelling(translationUnit: translationUnit)!) @ \(file) \(function):\(line)", token.sourceLocation(translationUnit: translationUnit))
  }
}
