import Clang

extension CXSourceLocation: Into {
  typealias T = OctoOrigin
  func into() -> T {
    return OctoOrigin(c: self)
  }
}

extension CXCursor: Into {
  typealias T = OctoLibrary.LangId
  func into() -> T {
    return .c(self)
  }
}
