import Foundation
import Clang

struct ParseConfiguration {
  let outputLibraryName: String
  let outputLocation: URL
  let languageSpecificConfig: LanguageSpecificConfiguration

  struct CConfig {
    let headerFile: URL
    let clangFlags: [Substring]
    let includeHeaders: [Substring]
    /// The libraries to link against
    let link: [Substring]
    let logLevel: CXDiagnosticSeverity
    let errorLevel: CXDiagnosticSeverity
  }

  enum LanguageSpecificConfiguration {
    case c(CConfig)
  }

  var cConfig: CConfig? {
    switch (self.languageSpecificConfig) {
      case .c(let config):
        return config
      default:
        return nil
    }
  }
}
