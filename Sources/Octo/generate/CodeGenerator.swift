import Foundation

public struct CodeGenerator {
  public static func generate(language lang: Language, lib: OctoLibrary, options: GenerationOptions) -> any GeneratedCode {
    switch (lang) {
      case .ruby:
        return lib.rubyGenerate(options: options)
      default:
        fatalError("Generation of \(lang) code is not yet implemented")
    }
  }
}

public struct GenerationOptions {
  public let indent: String
  /// Libraries to link against
  public let libs: [String]

  public init(
    indent: String,
    libs: [String]
  ) {
    self.indent = indent
    self.libs = libs
  }
}

public protocol GeneratedCode: CustomStringConvertible {
  func write(to url: URL) throws
}

func indentCode(indent: String, @StringBuilder _ str: () -> String) -> String {
  str().split(whereSeparator: \.isNewline)
    .map { "\(indent)\($0)" }
    .joined(separator: "\n")
}
