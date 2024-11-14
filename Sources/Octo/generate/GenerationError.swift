import Foundation

struct GenerationError: Error, CustomStringConvertible {
  let origin: OctoOrigin?
  let message: String
  let language: Language

  init(
    _ message: String,
    _ language: Language,
    _ origin: OctoOrigin? = nil
  ) {
    self.message = message
    self.language = language
    self.origin = origin
  }

  var description: String {
    var prefix = ""
    if let origin = self.origin {
      prefix += "\(URL(fileURLWithPath: origin.file).relativePath)"
    }
    return "\(prefix)[ERROR] While generating \(self.language) code: \(message)"
  }
}
