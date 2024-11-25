import Foundation
import OctoIntermediate

struct GenerationError: Error {
  let message: String
  let language: Language
  let origin: OctoOrigin?

  init(
    _ message: String,
    _ language: Language,
    origin: OctoOrigin? = nil
  ) {
    self.message = message
    self.language = language
    self.origin = origin
  }
}

extension GenerationError: CustomStringConvertible {
  public var description: String {
    var msg = "Error generating \(self.language) code: \(self.message)"
    if let origin = self.origin {
      msg += " at \(origin)"
    }
    return msg
  }
}

/// Thrown when an OctoType cannot be represented in the target language
public struct UnsupportedType: Error {
  /// The target language
  let language: Language
  let type: OctoType
}
