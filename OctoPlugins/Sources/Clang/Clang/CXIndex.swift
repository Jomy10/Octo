import clang_c

extension CXIndex {
  public init?(excludeDeclarationsFromPCH: Bool, displayDiagnostics: Bool) {
    self = clang_createIndex(excludeDeclarationsFromPCH ? 1 : 0, displayDiagnostics ? 1 : 0)
  }

  public func dispose() {
    clang_disposeIndex(self)
  }
}
