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

    enum CodingKeys: String, CodingKey {
      case clangFlags = "flags"
      case includeHeaders = "include"
      case logLevel
      case errorLevel
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.clangFlags = try container.decodeIfPresent([String].self, forKey: .clangFlags) ?? []
      self.includeHeaders = try container.decodeIfPresent([String].self, forKey: .includeHeaders) ?? []
      self.logLevel = try container.decodeIfPresent(ClangDiagnostic.self, forKey: .logLevel) ?? .warning
      self.errorLevel = try container.decodeIfPresent(ClangDiagnostic.self, forKey: .errorLevel) ?? .error
    }

  }

  var cConfig: CConfig? {
    switch (self.languageSpecificConfig) {
      case .c(let config): return config
    }
  }
}
