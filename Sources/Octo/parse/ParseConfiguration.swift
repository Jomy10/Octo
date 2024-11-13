import Foundation
import Clang

public enum ClangDiagnostic {
  case ignored
  case note
  case warning
  case error
  case fatal

  public init?(fromString string: some StringProtocol) {
    switch (string) {
      case "ignored": self = .ignored
      case "note": self = .note
      case "warning": self = .warning
      case "error": self = .error
      case "fatal": self = .fatal
      default: return nil
    }
  }

  var cxDiagnosticSeverity: CXDiagnosticSeverity {
    switch (self) {
      case .ignored: return CXDiagnostic_Ignored
      case .note: return CXDiagnostic_Note
      case .warning: return CXDiagnostic_Warning
      case .error: return CXDiagnostic_Error
      case .fatal: return CXDiagnostic_Fatal
    }
  }
}

public struct ParseConfiguration {
  public let outputLibraryName: String
  public let outputLocation: URL
  public let languageSpecificConfig: LanguageSpecificConfiguration

  public struct CConfig {
    public let headerFile: URL
    public let clangFlags: [Substring]
    public let includeHeaders: [Substring]
    public let logLevel: ClangDiagnostic
    public let errorLevel: ClangDiagnostic

    public init(
      headerFile: URL,
      clangFlags: [Substring],
      includeHeaders: [Substring],
      logLevel: ClangDiagnostic = .note,
      errorLevel: ClangDiagnostic = .error
    ) {
      self.headerFile = headerFile
      self.clangFlags = clangFlags
      self.includeHeaders = includeHeaders
      self.logLevel = logLevel
      self.errorLevel = errorLevel
    }
  }

  public init(
    outputLibraryName: some StringProtocol,
    outputLocation: URL,
    languageSpecificConfig: LanguageSpecificConfiguration
  ) {
    self.outputLibraryName = String(outputLibraryName)
    self.outputLocation = outputLocation
    self.languageSpecificConfig = languageSpecificConfig
  }

  public enum LanguageSpecificConfiguration {
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
