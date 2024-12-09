import Foundation
import OctoIntermediate
import OctoGenerateShared

struct RubyCode: GeneratedCode {
  let code: String

  func write(to url: URL) throws {
    try self.code.write(to: url, atomically: true, encoding: .utf8)
  }

  var description: String {
    return code
  }
}

protocol RubyCodeGenerator {
  func generateRubyFFICode(options: GenerationOptions, in lib: OctoLibrary) throws -> String
  func generateRubyBindingCode(options: GenerationOptions, in lib: OctoLibrary, ffiModuleName: String) throws -> String
}
