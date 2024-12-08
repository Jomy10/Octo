public protocol AutoRemovable {
  var destroy: () -> Void { get set }
}

public class AutoRemoveReference<T: AutoRemovable> {
  public var inner: T

  public init(_ inner: T) {
    self.inner = inner
  }

  deinit {
    self.inner.destroy()
  }
}
