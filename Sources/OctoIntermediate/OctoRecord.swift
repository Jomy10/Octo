// Record //

public final class OctoRecord: OctoObject, OctoFunctionAttachable {
  public let type: RecordType
  public private(set) var fields: [OctoField]

  public enum RecordType: Equatable {
    case `struct`
    case `union`
  }

  // Attached Functions //
  public var initializers: [OctoFunction]
  public var deinitializer: OctoFunction?
  public var methods: [OctoFunction]
  public var staticMethods: [OctoFunction]

  public init(
    origin: OctoOrigin,
    name: String,
    type: RecordType,
    fields: [OctoField] = [],
    initializers: [OctoFunction] = [],
    deinitializer: OctoFunction? = nil,
    methods: [OctoFunction] = [],
    staticMethods: [OctoFunction] = []
  ) {
    self.type = type
    self.fields = fields
    self.initializers = initializers
    self.deinitializer = deinitializer
    self.methods = methods
    self.staticMethods = staticMethods
    super.init(origin: origin, name: name)
  }

  public func addField(_ field: OctoField) {
    self.fields.append(field)
  }
}

// Field //

public final class OctoField: OctoObject {
  public private(set) var type: OctoType

  public init(
    origin: OctoOrigin,
    name: String,
    type: OctoType
  ) {
    self.type = type
    super.init(origin: origin, name: name)
  }

  public override func setNullable(_ val: Bool) throws {
    self.type.optional = val
  }
}
