import clang_c

extension CXPrintingPolicy {
  public var managed: ManagedCXPrintingPolicy {
    ManagedCXPrintingPolicy(self)
  }

  public func getProperty(_ property: CXPrintingPolicyProperty) -> UInt32 {
    clang_PrintingPolicy_getProperty(self, property)
  }

  public func setProperty(_ property: CXPrintingPolicyProperty, _ value: UInt32) {
    clang_PrintingPolicy_setProperty(self, property, value)
  }
}

public class ManagedCXPrintingPolicy {
  public let ptr: CXPrintingPolicy

  init(_ ptr: CXPrintingPolicy) {
    self.ptr = ptr
  }

  public func getProperty(_ property: CXPrintingPolicyProperty) -> UInt32 {
    self.ptr.getProperty(property)
  }

  public func setProperty(_ property: CXPrintingPolicyProperty, _ value: UInt32) {
    self.ptr.setProperty(property, value)
  }

  deinit {
    clang_PrintingPolicy_dispose(self.ptr)
  }
}
