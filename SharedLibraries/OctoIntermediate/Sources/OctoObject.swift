import Foundation

public class OctoObject: Equatable, Hashable {
  private let id = UUID()

  public let origin: OctoOrigin
  public let ffiName: String?
  private var customName: String? = nil
  /// Nil if object is unnamed
  public var bindingName: String? {
    self.customName ?? self.ffiName
  }

  init(origin: OctoOrigin, name: String?) {
    self.origin = origin
    self.ffiName = name
  }

  public func rename(to newName: String) {
    self.customName = newName
  }

  public static func ==(lhs: OctoObject, rhs: OctoObject) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }

  public func attach(to object: any OctoFunctionAttachable, kind: OctoFunction.FunctionType = .method) throws {
    throw AttributeError("'attach' attribute can only be used on functions")
  }

  public func setNullable(_ val: Bool) throws {
    throw AttributeError("Cannot mark \(self) as '\(val ? "nullabele" : "nonnull")'")
  }

  public func setReturnsNonNull(_ vali: Bool) throws {
    throw AttributeError("'returns_nonnull' attribute can only be used on functions")
  }

  public func setTaggedUnion() throws {
    throw AttributeError("'taggedUnion' attribute can only be used on structs")
  }

  public func setEnumPrefix(prefix: String) throws {
    throw AttributeError("'enumPrefix' attribute can only be used on enums")
  }

  public func setTaggedUnionType(enumCase: String) throws {
    throw AttributeError("'taggedUnionType' attribute can only be used on union fields")
  }

  public func addAttribute(_ attr: OctoAttribute) throws {
    switch (attr) {
      case .rename(to: let name):
        self.rename(to: name)
      case .attach(to: let obj, type: let type):
        try self.attach(to: obj, kind: type)
      case .taggedUnion:
        try self.setTaggedUnion()
      case .enumPrefix(prefix: let prefix):
        try self.setEnumPrefix(prefix: prefix)
      case .taggedUnionType(enumCase: let enumCase):
        try self.setTaggedUnionType(enumCase: enumCase)
      case .nonnull:
        try self.setNullable(false)
      case .nullable:
        try self.setNullable(true)
      case .returnsNonNull:
        try self.setReturnsNonNull(true)
    }
  }

  func finalize(_ lib: OctoLibrary) throws {}
}
