import clang_c

public protocol CXKind {
  var spelling: String? { get }
  var kindName: String { get }
  var rawValue: UInt32 { get }
}

extension CXCursorKind: CXKind {
  public var spelling: String? {
    clang_getCursorKindSpelling(self).toString()
  }

  public var kindName: String {
    "cursor kind"
  }
}

extension CXTypeKind: CXKind {
  public var spelling: String? {
    clang_getTypeKindSpelling(self).toString()
  }

  public var kindName: String {
    "type kind"
  }
}

extension CXTokenKind: CXKind {
  public var spelling: String? {
    return nil
  }

  public var kindName: String {
    "token kind"
  }
}
