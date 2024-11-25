import Foundation
import OctoIntermediate
import StringBuilder

public struct OctoGenerator {
  public static func generate(language: Language, lib: inout OctoLibrary, options: GenerationOptions) throws -> any GeneratedCode {
    try lib.finalize()
    switch (language) {
      case .ruby:
        return try lib.rubyGenerate(options: options)
      default:
        throw GenerationError("Generation of \(language) code is not yet implemented", language)
    }
  }
}

public protocol GeneratedCode {
  func write(to url: URL) throws
}

func indentCode(indent: String, @StringBuilder _ str: () throws -> String) rethrows -> String {
  try str().split(whereSeparator: \.isNewline)
    .map { "\(indent)\($0)" }
    .joined(separator: "\n")
}
