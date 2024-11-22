// Enum //

public final class OctoEnum: OctoObject, OctoFunctionAttachable {
  /// Usually an integer type, but can be any other type, depending oon the language
  public let type: OctoType
  public var cases: [OctoEnumCase]

  // Attached Functions //
  public var initializers: [OctoFunction]
  public var deinitializer: OctoFunction?
  public var methods: [OctoFunction]
  public var staticMethods: [OctoFunction]

  public init(
    origin: OctoOrigin,
    name: String,
    type: OctoType,
    cases: [OctoEnumCase] = [],
    initializers: [OctoFunction] = [],
    deinitializer: OctoFunction? = nil,
    methods: [OctoFunction] = [],
    staticMethods: [OctoFunction] = []
  ) {
    self.type = type
    self.cases = cases
    self.initializers = initializers
    self.deinitializer = deinitializer
    self.methods = methods
    self.staticMethods = staticMethods
    super.init(origin: origin, name: name)
  }

  public func addCase(_ ec: OctoEnumCase) {
    self.cases.append(ec)
  }
}

// Enum Case //

public final class OctoEnumCase: OctoObject {
  /// Depends on the type of the OctoEnum
  public let value: Value?

  public enum Value: Equatable {
    /// A signed integer
    case int(Int64)
    /// An unsigned integer
    case uint(UInt64)
  }

  public init(
    origin: OctoOrigin,
    name: String,
    value: Value? = nil
  ) {
    self.value = value
    super.init(origin: origin, name: name)
  }
}
