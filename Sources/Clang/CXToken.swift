import clang_c

extension CXToken {
  public var kind: CXTokenKind {
    clang_getTokenKind(self)
  }

  public func spelling(translationUnit: CXTranslationUnit) -> String? {
    clang_getTokenSpelling(translationUnit, self).toString()
  }

  public func sourceLocation(translationUnit: CXTranslationUnit) -> CXSourceLocation {
    clang_getTokenLocation(translationUnit, self)
  }
}
