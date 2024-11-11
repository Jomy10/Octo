import Clang

struct OctoType: CustomStringConvertible, Equatable {
  private let inner: CXType // TODO: language agnostic
  let kind: OctoTypeKind
  /// Nullable for ptr types and function types
  var nullable = true

  var isMutable: Bool {
    !self.inner.isConstQualifiedType
  }

  /// Size in bytes of the type
  var size: Int64 {
    self.inner.size
  }

  private init(
    inner: CXType,
    kind: OctoTypeKind,
    nullable: Bool
  ) {
    self.inner = inner
    self.kind = kind
    self.nullable = nullable
  }

  init?(cxType: CXType) {
    guard let kind = OctoTypeKind(cxType: cxType) else {
      return nil
    }
    self.kind = kind
    self.inner = cxType
  }

  public var description: String {
    "\(self.isMutable ? "mut" : "const") \(self.kind)\(self.kind.isPtr && self.nullable ? "?" : "")"
  }

  public static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.inner == rhs.inner
  }

  public func copy(mutatingKind kind: OctoTypeKind) -> Self {
    OctoType(
      inner: self.inner,
      kind: kind,
      nullable: nullable
    )
  }

  var containsUserType: Bool {
    switch (self.kind) {
      case .Pointer(to: let type):
        return type.containsUserType
      case .UserDefined(name: _):
        return true
      case .ConstantArray(type: let type, size: _):
        return type.containsUserType
      case .Function(callingConv: _, args: let args, result: let resultType):
        return (args.first(where: { $0.containsUserType }) != nil) || (resultType.containsUserType)
      default:
        return false
    }
  }
}

enum OctoTypeKind: Equatable {
  case Void
  case Bool
  case U8
  case S8
  /// wchar_t
  case WChar
  case U16
  case S16
  case U32
  case S32
  case U64
  case S64
  case U128
  case S128
  case F32
  case F64
  /// long double -> can be either 96 or 128 bits
  case FLong
  indirect case Pointer(to: OctoType)
  indirect case Function(
    callingConv: OctoCallingConv,
    args: [OctoType],
    result: OctoType
  )
  indirect case ConstantArray(type: OctoType, size: Int64)
  case UserDefined(name: String)
}

extension OctoTypeKind {
  init?(cxType: CXType) {
    switch (cxType.kind) {
      case CXType_Invalid: return nil
      case CXType_Void: self = .Void
      case CXType_Bool: self = .Bool
      case CXType_Char16: self = .S16
      case CXType_Char32: self = .S32
      case CXType_WChar: self = .WChar
      case CXType_Char_U: fallthrough
      case CXType_UChar: fallthrough
      case CXType_UShort: fallthrough
      case CXType_UInt: fallthrough
      case CXType_ULong: fallthrough
      case CXType_ULongLong: fallthrough
      case CXType_UInt128:
        switch (cxType.size) {
          case 8 / 8: self = .U8
          case 16 / 8: self = .U16
          case 32 / 8: self = .U32
          case 64 / 8: self = .U64
          case 128 / 8: self = .U128
          default:
            fatalError("Invalid length for unsigned integer variant \(cxType.size) bytes")
        }
      case CXType_Char_S: fallthrough
      case CXType_SChar: fallthrough
      case CXType_Short: fallthrough
      case CXType_Int: fallthrough
      case CXType_Long: fallthrough
      case CXType_LongLong: fallthrough
      case CXType_Int128:
        switch (cxType.size) {
          case 8 / 8: self = .S8
          case 16 / 8: self = .S16
          case 32 / 8: self = .S32
          case 64 / 8: self = .S64
          case 128 / 8: self = .S128
          default:
            fatalError("Invalid length for signed integer variant \(cxType.size) bytes")
        }
      case CXType_Float: self = .F32
      case CXType_Double: self = .F64
      case CXType_LongDouble: self = .FLong
      case CXType_Pointer:
        guard let type = OctoType(cxType: cxType.pointeeType) else { unhandledKind(cxType.pointeeType.kind) }
        self = .Pointer(to: type)
      //case CXType_LValueReference: // &
      //  guard let type = CType(cxType: cxType.pointeeType) else { unhandledKind(cxType.pointeeType.kind) }
      //  self = .LValueReference(to: type)
      //case CXType_RValueReference: // &&
      //  guard let type = CType(cxType: cxType.pointeeType) else { unhandledKind(cxType.pointeeType.kind) }
      //  self = .RValueReference(to: type)
      case CXType_FunctionProto: fallthrough
      case CXType_FunctionNoProto:
        guard let resultType = OctoType(cxType: cxType.resultType) else { unhandledKind(cxType.resultType.kind) }
        let callingConv = OctoCallingConv(cxCallingConv: cxType.functionTypeCallingConv)
        let argTypes = cxType.argTypes.map { cxt in
          guard let ty = OctoType(cxType: cxt) else {
            unhandledKind(cxt.kind)
          }
          return ty
        }
        self = .Function(callingConv: callingConv, args: argTypes, result: resultType)
      case CXType_Elaborated:
        let parts = cxType.spelling!.split(separator: " ")
        //self = .UserType(name: parts.last!, prefix: parts.count > 1 ? parts[0..<parts.count-1].joined(separator: " ") : nil)
        self = .UserDefined(name: String(parts.last!))
      case CXType_ConstantArray:
        guard let type = OctoType(cxType: cxType.arrayElementType) else {
          unhandledKind(cxType.arrayElementType.kind)
        }
        let size: Int64 = cxType.arraySize
        self = .ConstantArray(type: type, size: size)
      default:
        return nil
    }
  }

  var isSigned: Bool? {
    switch (self) {
      case .S8: fallthrough
      case .S16: fallthrough
      case .S32: fallthrough
      case .S64: fallthrough
      case .S128:
        return true
      case .U8: fallthrough
      case .U16: fallthrough
      case .U32: fallthrough
      case .U64: fallthrough
      case .U128:
        return false
      default: return nil
    }
  }

  var isPtr: Bool {
    if case .Pointer(to: _) = self {
      return true
    } else {
      return false
    }
  }
}

enum OctoCallingConv {
  case `default`
  case c
  case swift
  case swiftAsync
  case win64
  case invalid

  init(cxCallingConv: CXCallingConv) {
    switch (cxCallingConv) {
      case CXCallingConv_Default: self = .`default`
      case CXCallingConv_C: self = .c
      case CXCallingConv_Swift: self = .swift
      case CXCallingConv_SwiftAsync: self = .swiftAsync
      case CXCallingConv_Win64: self = .win64
      case CXCallingConv_Invalid: self = .invalid
      default: fatalError("unimplemented")
    }
  }
}
