public struct OctoType: Equatable {
  public var kind: OctoType.Kind
  public var optional: Bool
  public var mutable: Bool

  public init(
    kind: OctoType.Kind,
    optional: Bool,
    mutable: Bool
  ) {
    self.kind = kind
    self.optional = optional
    self.mutable = mutable
  }

  public enum Kind: Equatable {
    case Void
    case Bool
    case I8
    case I16
    case I32
    case I64
    case I128
    case U8
    case U16
    case U32
    case U64
    case U128
    case F32
    case F64
    /// long double -> can be either 96 or 128 bits
    case FLong
    /// An 8-bit character.
    case Char8
    /// Same as `Char8`, but representing a byte instead of a character
    case Byte
    /// A unicode scalar, maps to a character type in most languages
    /// e.g. `wchar_t`, `char16_t`
    /// - `bitCharSize`
    ///   The size of the character is specified by `bitCharSize`. The actual type can be of a different size
    ///   Can be nil of no explicit size is given
    ///   bitCharSize also specifies UTF-`bitCharSize`
    case UnicodeScalar(bitCharSize: Int? = nil)
    /// e.g. `char*`, `wchar_t*`
    case String
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
