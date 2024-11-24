import Foundation
import OctoIntermediate
import ExpressionInterpreter

struct ConfigError: Error {
  let message: String

  init(_ message: String) {
    self.message = message
  }
}

struct OctoConfig {
  // General //
  let outputLibraryName: String
  /// The libraries to link against
  let link: [String]

  // Input (parse) options //
  /// The language to parse to which we want bindings
  let inputLanguage: Language
  /// Location of the file or directory to parse
  let inputLocation: URL
  /// Language-specific input options
  let langInOpts: (any LanguageInputOptionSet)?
  /// Extra octo attributes not defined in the source(s) (attach, rename, ...)
  let attributes: [Attribute]

  // Output (generation) options //
  let outputOptions: [Language: OutputOptions]

  // Rename //
  /// A set of operations to rename the input symbols to the output
  let renameOperations: [Program]

  struct OutputOptions {
    /// The output file or directory
    let outputLocation: URL
    /// Language-specific output options
    let langOutOpts: (any LanguageOutputOptionSet)?
    let indentCount: Int
    let indentType: IndentType
    /// Language-specific rename operations
    let renameOperations: [Program]
  }
}

// Computed properties //

extension OctoConfig.OutputOptions {
  var indent: String {
    String(repeating: self.indentType == .spaces ? " " : "\t", count: self.indentCount)
  }
}
