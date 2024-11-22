import Foundation

extension ParseConfiguration {
  public struct CConfig {
    public let clangFlags: [String]
    public let includeHeaders: [String]
    /// Which log levels to print
    public let logLevel: ClangDiagnostic
    /// At which level to exit
    public let errorLevel: ClangDiagnostic
  }

  var cConfig: CConfig? {
    switch (self.languageSpecificConfig) {
      case .c(let config): return config
    }
  }
}
