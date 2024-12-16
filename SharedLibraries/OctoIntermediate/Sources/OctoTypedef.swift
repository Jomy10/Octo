@available(*, deprecated, message: "Use `OctoLibrary.addTypedef` instead")
public final class OctoTypedef: OctoObject {
  public private(set) var refersTo: OctoType
  private let refersToDeferred: ((OctoLibrary) throws -> OctoType)?

  public init(
    origin: OctoOrigin,
    name: String,
    refersTo: OctoType
  ) {
    self.refersTo = refersTo
    self.refersToDeferred = nil
    super.init(origin: origin, name: name)
  }

  public init(
    origin: OctoOrigin,
    name: String,
    refersToDeferred: @escaping (OctoLibrary) throws -> OctoType
  ) {
    self.refersTo = OctoType(kind: .Void, optional: false, mutable: false)
    self.refersToDeferred = refersToDeferred
    super.init(origin: origin, name: name)
  }

  public override func rename(to newName: String) {
    super.rename(to: newName)
    switch (self.refersTo.kind) {
      case .Record(let record):
        if record.ffiName == self.ffiName {
          record.rename(to: newName)
        }
      case .Enum(let e):
        if e.ffiName == self.ffiName {
          e.rename(to: newName)
        }
      default:
        break
    }
  }

  public var mustFinalize: Bool {
    self.refersToDeferred != nil
  }

  override func finalize(_ lib: OctoLibrary) throws {
    if let refersToDeferred = self.refersToDeferred {
      self.refersTo = try refersToDeferred(lib)
    }
    self.refersTo.finalize(lib)
    try super.finalize(lib)
  }
}

extension OctoTypedef: CustomDebugStringConvertible {
  public var debugDescription: String {
    "@typedef \(self.bindingName!) = \(String(reflecting: self.refersTo))"
  }
}
