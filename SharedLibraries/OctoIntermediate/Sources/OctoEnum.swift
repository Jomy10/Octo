import OctoIO

// Enum //

public final class OctoEnum: OctoObject, OctoFunctionAttachable {
  /// Usually an integer type, but can be any other type, depending oon the language
  public let type: OctoType
  public var cases: [OctoEnumCase]
  var enumPrefix: String? = nil

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

  public override func setEnumPrefix(prefix: String) throws {
    self.enumPrefix = prefix
  }

  override func finalize() throws {
    self.cases.forEach { enumCase in
      if let prefix = self.enumPrefix {
        if enumCase.ffiName!.hasPrefix(prefix) {
          enumCase.strippedName = String(enumCase.ffiName!.dropFirst(prefix.count))
        } else {
          OctoLibrary.logger.warning("Enum Case '\(enumCase.ffiName!)' of enum \(self.ffiName!) has no prefix \(prefix)")
          enumCase.strippedName = enumCase.ffiName
        }
      } else {
        enumCase.strippedName = enumCase.ffiName
      }
    }
  }
}

// Enum Case //

public final class OctoEnumCase: OctoObject {
  /// Depends on the type of the OctoEnum
  public let value: Value?
  /// This enum's case name without the enumPrefix
  public var strippedName: String? = nil

  public enum Value: Equatable {
    /// A signed integer
    case int(Int64)
    /// An unsigned integer
    case uint(UInt64)

    public var literalValue: String {
      switch (self) {
        case .int(let i): return "\(i)"
        case .uint(let i): return "\(i)"
      }
    }
  }

  public init(
    origin: OctoOrigin,
    name: String,
    value: Value? = nil
  ) {
    self.value = value
    super.init(origin: origin, name: name)
  }

  //public func nonPrefixedFfiName(parent: OctoEnum) -> String {
  //  if let prefix = parent.enumPrefix {
  //    let name = self.ffiName!
  //    if name.hasPrefix(prefix) {
  //      return String(name.dropFirst(prefix.count))
  //    } else {
  //      return name
  //    }
  //  } else {
  //    return self.ffiName!
  //  }
  //}
}

// String //

extension OctoEnum: CustomStringConvertible {
  public var description: String {
    "Enum(name: \(self.bindingName!))"
  }
}
