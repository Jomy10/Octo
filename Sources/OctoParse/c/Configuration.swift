import Foundation

extension ParseConfiguration {
  public struct CConfig: Decodable {
    public let clangFlags: [String]
    /// Which headers to include in parsing
    public let includeHeaders: [String]
    /// Which log levels to print
    public let logLevel: ClangDiagnostic
    /// At which level to exit
    public let errorLevel: ClangDiagnostic

    public init(
      clangFlags: [String],
      includeHeaders: [String],
      logLevel: ClangDiagnostic,
      errorLevel: ClangDiagnostic
    ) {
      self.clangFlags = clangFlags
      self.includeHeaders = includeHeaders
      self.logLevel = logLevel
      self.errorLevel = errorLevel
    }
  }

  var cConfig: CConfig? {
    switch (self.languageSpecificConfig) {
      case .c(let config): return config
    }
  }
}
