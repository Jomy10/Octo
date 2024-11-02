import clang_c

extension CXDiagnosticSeverity {
  public init?(fromString str: String) {
    switch (str) {
      case "ignored": self = CXDiagnostic_Ignored
      case "note": self = CXDiagnostic_Note
      case "warning": self = CXDiagnostic_Warning
      case "error": self = CXDiagnostic_Error
      case "fatal": self = CXDiagnostic_Fatal
      default: return nil
    }
  }
}
