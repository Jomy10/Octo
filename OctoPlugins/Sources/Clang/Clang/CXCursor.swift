import clang_c

public typealias VisitFn = @convention(c) (CXCursor, CXCursor, CXClientData?) -> CXChildVisitResult

extension CXCursor {
  public init(forTranslationUnit translationUnit: CXTranslationUnit) {
    self = clang_getTranslationUnitCursor(translationUnit)
  }

  public struct VisitChildrenBreak: Swift.Error {}

  public func visitChildren(_ visit: @escaping VisitFn) throws {
    if clang_visitChildren(self, visit, nil) != 0 {
      throw VisitChildrenBreak()
    }
  }

  public func visitChildren<UserData>(
    _ visit: @escaping VisitFn,
    userData: inout UserData
  ) throws {
    try withUnsafeMutablePointer(to: &userData) { dataPtr in
      if clang_visitChildren(self, visit, UnsafeMutableRawPointer(dataPtr)) != 0 {
        throw VisitChildrenBreak()
      }
    }
  }

  public var typedefDeclUnderlyingType: CXType {
    clang_getTypedefDeclUnderlyingType(self)
  }

  public var spelling: String? {
    clang_getCursorSpelling(self).toString()
  }

  public var cursorType: CXType {
    clang_getCursorType(self)
  }

  public var cursorLanguage: Language {
    switch (clang_getCursorLanguage(self)) {
      case CXLanguage_Invalid: return .invalid
      case CXLanguage_C: return .c
      case CXLanguage_ObjC: return .objC
      case CXLanguage_CPlusPlus: return .cxx
      default:
        fatalError("Unreachable")
    }
  }

  public var hasVarDeclGlobalStorage: Bool {
    clang_Cursor_hasVarDeclGlobalStorage(self) == 1
  }

  public var hasVarDeclExternalStorage: Bool {
    clang_Cursor_hasVarDeclExternalStorage(self) == 1
  }

  public var varDeclInitializer: CXCursor {
    clang_Cursor_getVarDeclInitializer(self)
  }

  public var enumDeclIntegerType: CXType {
    clang_getEnumDeclIntegerType(self)
  }

  public var enumConstantDeclUnsignedValue: UInt64 {
    clang_getEnumConstantDeclUnsignedValue(self)
  }

  public var enumConstantDeclValue: Int64 {
    clang_getEnumConstantDeclValue(self)
  }

  public var location: CXSourceLocation {
    clang_getCursorLocation(self)
  }

  public var semanticParent: CXCursor {
    clang_getCursorSemanticParent(self)
  }

  public var translationUnit: CXTranslationUnit {
    clang_Cursor_getTranslationUnit(self)
  }

  public var extent: CXSourceRange {
    clang_getCursorExtent(self)
  }

  public var printingPolicy: ManagedCXPrintingPolicy {
    clang_getCursorPrintingPolicy(self).managed
  }

  public func prettyPrint(_ policy: ManagedCXPrintingPolicy? = nil) -> CXString {
    clang_getCursorPrettyPrinted(self, policy?.ptr)
  }
}

extension CXCursor: Hashable, Equatable {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    clang_equalCursors(lhs, rhs) != 0
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(clang_hashCursor(self))
  }
}

public enum Language: Int32 {
  case invalid = 0
  case c
  case objC
  case cxx
}
