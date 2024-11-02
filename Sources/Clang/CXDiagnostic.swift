import clang_c

extension CXDiagnostic {
  public var severity: CXDiagnosticSeverity {
    clang_getDiagnosticSeverity(self)
  }

  public func format(_ options: UInt32) -> String {
    clang_formatDiagnostic(self, options).toString()!
  }
}
