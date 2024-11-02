import clang_c

public class ManagedCXString {
  private let cxString: CXString

  public init(cxString: CXString) {
    self.cxString = cxString
  }

  public var cStr: UnsafePointer<CChar>? {
    clang_getCString(self.cxString)
  }

  public var str: String? {
    if let cStr = self.cStr {
      return String(cString: cStr)
    } else {
      return nil
    }
  }

  deinit {
    self.cxString.dispose()
  }
}

extension CXString {
  public var managed: ManagedCXString {
    ManagedCXString(cxString: self)
  }

  public var cStr: UnsafePointer<CChar>? {
    clang_getCString(self)
  }

  public func toString() -> String? {
    if let cStr = self.cStr {
      let str = String(cString: cStr)
      self.dispose()
      return str
    } else {
      return nil
    }
  }

  public func dispose() {
    clang_disposeString(self)
  }
}
