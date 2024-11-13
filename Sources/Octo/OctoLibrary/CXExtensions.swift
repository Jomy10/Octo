import Clang

extension CXSourceLocation: Into {
  public typealias T = OctoOrigin
  public func into() -> T {
    return OctoOrigin(c: self)
  }
}

extension CXCursor: Into {
  public typealias T = OctoLibrary.LangId
  public func into() -> T {
    return .c(self)
  }
}
