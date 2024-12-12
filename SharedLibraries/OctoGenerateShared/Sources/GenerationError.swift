import Foundation
import OctoIntermediate

public struct GenerationError: Error {
  let message: String
  let language: Language
  let origin: OctoOrigin?

  public init(
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
  public let language: Language
  public let type: OctoType

  public init(language: Language, type: OctoType) {
    self.language = language
    self.type = type
  }
}

public struct UnsupportedFfiLanguage: Error {
  public let ffiLanguage: Language
  public let supported: [Language]

  public init(_ ffiLanguage: Language, supported: [Language]) {
    self.ffiLanguage = ffiLanguage
    self.supported = supported
  }
}
