import Foundation
import OctoIntermediate

struct GenerationError: Error {
  let origin: OctoOrigin?
  let message: String
  let language: Language

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

/// Thrown when an OctoType cannot be represented in the target language
public struct UnsupportedType: Error {
  /// The target language
  let language: Language
  let type: OctoType
}
