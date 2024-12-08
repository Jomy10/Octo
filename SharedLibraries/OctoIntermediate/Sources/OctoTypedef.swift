public final class OctoTypedef: OctoObject {
  public let refersTo: OctoType

  public init(
    origin: OctoOrigin,
    name: String,
    refersTo: OctoType
  ) {
    self.refersTo = refersTo
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
}
