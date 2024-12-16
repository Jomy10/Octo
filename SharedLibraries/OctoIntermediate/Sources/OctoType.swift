public struct OctoType: Equatable {
  public var kind: OctoType.Kind
  public var optional: Bool
  public var mutable: Bool
  /// resolve `kind` in finalize method
  public var resolveTypeKind: ((OctoLibrary) -> OctoType.Kind)? = nil

  public init(
    kind: OctoType.Kind,
    optional: Bool,
    mutable: Bool
  ) {
    self.kind = kind
    self.optional = optional
    self.mutable = mutable
  }

  enum Error: Swift.Error {
    case typeCannotBeCreatedFromObject(OctoObject)
  }

  public init(from object: OctoObject) throws {
    if let record = object as? OctoRecord {
      self.kind = .Record(record)
    } else if let e = object as? OctoEnum {
      self.kind = .Enum(e)
    } else {
      throw Self.Error.typeCannotBeCreatedFromObject(object)
    }
    self.optional = false // TODO
    self.mutable = true // TODO
  }

  public static func isUserType(_ type: OctoType) -> Bool {
    switch (type.kind) {
      case .Pointer(to: let type): return Self.isUserType(type)
      case .Record(_): return true
      case .Enum(_): return true
      default: return false
    }
  }

  public var isUserType: Bool {
    Self.isUserType(self)
  }

  public mutating func finalize(_ lib: OctoLibrary) {
    if let resolveTypeKind = self.resolveTypeKind {
      self.kind = resolveTypeKind(lib)
    }
  }

  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.kind == rhs.kind && lhs.optional == rhs.optional && lhs.mutable == rhs.optional
  }

  public enum Kind: Equatable {
    case Void
    case Bool

    case I8
    case I16
    case I32
    case I64
    case I128
    case ISize

    case U8
    case U16
    case U32
    case U64
    case U128
    case USize

    /// See also: https://pubs.opengroup.org/onlinepubs/009696799/basedefs/stdint.h.html
    case IntLeast(size: Int, sizeOnCurrentPlatform: Int)
    case UIntLeast(size: Int, sizeOnCurrentPlatform: Int)
    case IntFast(size: Int, sizeOnCurrentPlatform: Int)
    case UIntFast(size: Int, sizeOnCurrentPlatform: Int)
    case IntMax(sizeOnCurrentPlatform: Int)
    case UIntMax(sizeOnCurrentPlatform: Int)

    case F32
    case F64
    /// long double -> can be either 96 or 128 bits
    case FLong

    /// An 8-bit character.
    case Char8
    /// Same as `Char8`, but representing a byte instead of a character
    //case Byte
    /// A unicode scalar, maps to a character type in most languages
    /// e.g. `wchar_t`, `char16_t`
    /// - `bitCharSize`
    ///   The size of the character is specified by `bitCharSize`. The actual type can be of a different size
    ///   Can be nil of no explicit size is given
    ///   bitCharSize also specifies UTF-`bitCharSize`
    case UnicodeScalar(bitCharSize: Int? = nil)
    /// A null-terminated string
    /// e.g. `char*`
    case CString
    /// e.g. `wchar_t*`
    case UnicodeCString(scalarTypeSize: Int)

    indirect case Pointer(to: OctoType)
    indirect case Function(
      callingConv: OctoCallingConv,
      args: [OctoType],
      result: OctoType
    )
    indirect case ConstantArray(type: OctoType, size: Int64)
    case Record(OctoRecord)
    case Enum(OctoEnum)
  }
}

extension OctoType.Kind {
  /// Is integer type a signed integer
  public var isSignedInt: Bool? {
    switch (self) {
      case .I8: fallthrough
      case .I16: fallthrough
      case .I32: fallthrough
      case .I64: fallthrough
      case .I128:
        return true
      case .U8: fallthrough
      case .U16: fallthrough
      case .U32: fallthrough
      case .U64: fallthrough
      case .U128:
        return false
      default:
        return nil
    }
  }
}

// String //

extension OctoType: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "\(self.mutable ? "mut" : "const") \(self.optional ? "optional " : "")\(self.kind.description)"
  }
}

extension OctoType.Kind: CustomStringConvertible {
  public var description: String {
    switch (self) {
      case .Void: return "Void"
      case .Bool: return "Bool"
      case .I8: return "I8"
      case .I16: return "I16"
      case .I32: return "I32"
      case .I64: return "I64"
      case .I128: return "I128"
      case .ISize: return "ISize"
      case .U8: return "U8"
      case .U16: return "U16"
      case .U32: return "U32"
      case .U64: return "U64"
      case .U128: return "U128"
      case .USize: return "USize"
      case .IntLeast(size: let size, sizeOnCurrentPlatform: _): return "IntLeast(\(size))"
      case .UIntLeast(size: let size, sizeOnCurrentPlatform: _): return "UIntLeast(\(size))"
      case .IntFast(size: let size, sizeOnCurrentPlatform: _): return "IntFast(\(size))"
      case .UIntFast(size: let size, sizeOnCurrentPlatform: _): return "UIntFast(\(size))"
      case .IntMax(sizeOnCurrentPlatform: _): return "IntMax"
      case .UIntMax(sizeOnCurrentPlatform: _): return "UIntMax"
      case .F32: return "F32"
      case .F64: return "F64"
      case .FLong: return "FLong"
      case .Char8: return "Char8"
      case .UnicodeScalar(bitCharSize: let size): return "UnicodeScalar(\(size?.description ?? "?")"
      case .CString: return "CString"
      case .UnicodeCString(scalarTypeSize: let scalarSize): return "UnicodeCString(\(scalarSize))"
      case .Pointer(to: let pointeeType): return "Pointer(to: \(pointeeType))"
      case .Function(callingConv: let callingConv, args: let args, result: let resultType): return "Function(\(callingConv), args: \(args), result: \(resultType))"
      case .ConstantArray(type: let itemType, size: let size): return "ConstantArray(\(itemType), \(size))"
      case .Record(let record): return record.description
      case .Enum(let e): return e.description
    }
  }
}
