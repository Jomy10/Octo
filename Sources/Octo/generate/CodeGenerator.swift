import Foundation

struct CodeGenerator {
  static func generate(language lang: Language, lib: OctoLibrary, options: GenerationOptions) -> any GeneratedCode {
    switch (lang) {
      case .ruby:
        return lib.rubyGenerate(options: options)
      default:
        fatalError("Generation of \(lang) code is not yet implemented")
    }
  }
}

struct GenerationOptions {
  let indent: String
  /// Libraries to link against
  let libs: [String]
}

protocol GeneratedCode: CustomStringConvertible {
  func write(to url: URL) throws
}

func indentCode(indent: String, @StringBuilder _ str: () -> String) -> String {
  str().split(whereSeparator: \.isNewline)
    .map { "\(indent)\($0)" }
    .joined(separator: "\n")
}
