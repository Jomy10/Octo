import Foundation
import OctoIntermediate
import OctoGenerateShared

struct CCode: GeneratedCode {
  let code: String

  func write(to url: URL) throws {
    try self.code.write(to: url, atomically: true, encoding: .utf8)
  }

  var description: String {
    return code
  }
}

protocol CCodeGenerator {
  func generateHeaderCode(options: GenerationOptions, in lib: OctoLibrary) throws -> String
}
