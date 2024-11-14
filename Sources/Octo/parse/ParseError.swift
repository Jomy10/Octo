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
}
