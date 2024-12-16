// Record //

public final class OctoRecord: OctoObject, OctoFunctionAttachable {
  public private(set) var type: RecordType
  public private(set) var fields: [OctoField]

  public private(set) var taggedUnionTagIndex: Int? = nil
  public var taggedUnionValueIndex: Int? { self.taggedUnionTagIndex == nil ? nil : (self.taggedUnionTagIndex! == 0 ? 1 : 0) }

  public var taggedUnionEnumType: OctoType? {
    guard let idx = self.taggedUnionTagIndex else { return nil }
    return self.fields[idx].type
  }

  public var taggedUnionValueType: OctoType? {
    guard let idx = self.taggedUnionTagIndex else { return nil }
    return self.fields[idx].type
  }

  public enum RecordType: Equatable {
    case `struct`
    case `union`
    case taggedUnion
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

  enum TaggedUnionError: Error {
    case expected2Fields(found: Int)
    /// Expected a field with an enum
    case noTagField
    /// Expected a field with a union
    case noValueField
    /// Only structs can be marked as a tagged union
    case notStruct
  }

  public override func setTaggedUnion() throws {
    if self.type != .`struct` {
      throw TaggedUnionError.notStruct
    }
    self.type = .taggedUnion
  }

  override func finalize(_ lib: OctoLibrary) throws {
    if self.type == .taggedUnion {
      if self.fields.count != 2 {
        throw TaggedUnionError.expected2Fields(found: self.fields.count)
      }
      if let tagIndex = fields.firstIndex(where: { field in if case .Enum(_) = field.type.kind { return true } else { return false } }) {
        self.taggedUnionTagIndex = tagIndex
        if case .Record(let record) = self.fields[self.taggedUnionValueIndex!].type.kind {
          if record.type != .union { throw TaggedUnionError.noValueField }
        } else {
          throw TaggedUnionError.noValueField
        }
      } else {
        throw TaggedUnionError.noTagField
      }
    }
    try super.finalize(lib)
  }
}

// Field //

public final class OctoField: OctoObject {
  public private(set) var type: OctoType
  public private(set) var taggedUnionCaseName: String? = nil

  public init(
    origin: OctoOrigin,
    name: String,
    type: OctoType
  ) {
    self.type = type
    super.init(origin: origin, name: name)
  }

  /// Find the enum case corresponding to this tagged union value field
  public func taggedUnionCase(in lib: OctoLibrary, enumType: OctoEnum) -> OctoEnumCase? {
    enumType.cases.first(where: { enumCase in
      (enumCase.ffiName! == (self.taggedUnionCaseName ?? self.ffiName!))
        || (enumCase.ffiName!.uppercased() == self.ffiName!.uppercased())
    })
  }

  public override func setNullable(_ val: Bool) throws {
    self.type.optional = val
  }

  public override func setTaggedUnionType(enumCase: String) throws {
    self.taggedUnionCaseName = enumCase
  }

  override func finalize(_ lib: OctoLibrary) throws {
    self.type.finalize(lib)
    try super.finalize(lib)
  }
}

// String //

extension OctoRecord: CustomStringConvertible {
  public var description: String {
    "Record(name: \(self.bindingName!))"
  }
}

extension OctoRecord: CustomDebugStringConvertible {
  public var debugDescription: String {
    var msg = "@Record.\(self.type) \(self.bindingName!)"
    for field in self.fields {
      msg += "\n  \(String(reflecting: field))"
    }
    return msg
  }
}

extension OctoField: CustomDebugStringConvertible {
  public var debugDescription: String {
    "@Field \(self.bindingName!) \(self.type)"
  }
}
