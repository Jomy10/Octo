import Clang

public enum ClangDiagnostic: Decodable {
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
