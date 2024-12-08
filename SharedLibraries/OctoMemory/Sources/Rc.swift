public final class Rc<T> {
  var inner: T

  public init(_ inner: T) {
    self.inner = inner
  }

  public func takeInner() -> T {
    self.inner
  }

  public func withInner<Result>(_ cb: (inout T) throws -> Result) rethrows -> Result {
    return try cb(&self.inner)
  }
}
