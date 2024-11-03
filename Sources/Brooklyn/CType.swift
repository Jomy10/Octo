import Clang

struct CType: CustomStringConvertible, Equatable {
  private let inner: CXType
  let kind: CTypeKind
  private static var _wcharSize: Int? = nil

  var isConst: Bool {
    self.inner.isConstQualifiedType
  }

  public var size: Int64 {
    self.inner.size
  }

  public init?(cxType: CXType) {
    guard let kind = CTypeKind(cxType: cxType) else {
      return nil
    }
    self.kind = kind
    self.inner = cxType
  }

  public var description: String {
    "\(self.isConst ? "const " : "")\(self.kind)"
  }

  public static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.inner == rhs.inner
  }
}

enum CTypeKind: Equatable {
  case Invalid
  case Void
  case Bool
  case Char_U
  case UChar // unsigned char
  case Char_S // char
  case SChar // signed char
  case WChar
  case Char16
  case Char32
  case UShort
  case UInt
  case ULong
  case ULongLong
  case UInt128
  case Short
  case Int
  case Long
  case LongLong
  case Int128
  case Float
  case Double
  case LongDouble
  indirect case Pointer(to: CType)
  indirect case LValueReference(to: CType)
  indirect case RValueReference(to: CType)
  /// for calling convention see [https://clang.llvm.org/doxygen/group__CINDEX__TYPES.html#ga4a0e941ec7b4b64bf9eb3d0ed49d55ae]
  indirect case FunctionProto(callingConv: CXCallingConv, args: [CType], result: CType)
  indirect case FunctionNoProto(callingConv: CXCallingConv, args: [CType], result: CType)
  indirect case ConstantArray(type: CType, size: Int64)
  case Elaborated(name: Substring, prefix: String? = nil)
}

extension CTypeKind {
  init?(cxType: CXType) {
    switch (cxType.kind) {
      case CXType_Invalid: self = .Invalid
      case CXType_Void: self = .Void
      case CXType_Bool: self = .Bool
      case CXType_Char_U: self = .Char_U
      case CXType_UChar: self = .UChar
      case CXType_Char16: self = .Char16
      case CXType_Char32: self = .Char32
      case CXType_UShort: self = .UShort
      case CXType_UInt: self = .UInt
      case CXType_ULong: self = .ULong
      case CXType_ULongLong: self = .ULongLong
      case CXType_UInt128: self = .UInt128
      case CXType_Char_S: self = .Char_S
      case CXType_SChar: self = .SChar
      case CXType_WChar: self = .WChar
      case CXType_Short: self = .Short
      case CXType_Int: self = .Int
      case CXType_Long: self = .Long
      case CXType_LongLong: self = .LongLong
      case CXType_Int128: self = .Int128
      case CXType_Float: self = .Float
      case CXType_Double: self = .Double
      case CXType_LongDouble: self = .LongDouble
      case CXType_Pointer:
        guard let type = CType(cxType: cxType.pointeeType) else { unhandledKind(cxType.pointeeType.kind) }
        self = .Pointer(to: type)
      case CXType_LValueReference: // &
        guard let type = CType(cxType: cxType.pointeeType) else { unhandledKind(cxType.pointeeType.kind) }
        self = .LValueReference(to: type)
      case CXType_RValueReference: // &&
        guard let type = CType(cxType: cxType.pointeeType) else { unhandledKind(cxType.pointeeType.kind) }
        self = .RValueReference(to: type)
      case CXType_FunctionProto: fallthrough
      case CXType_FunctionNoProto:
        guard let resultType = CType(cxType: cxType.resultType) else { unhandledKind(cxType.resultType.kind) }
        let callingConv = cxType.functionTypeCallingConv
        let argTypes = cxType.argTypes.map { cxt in
          guard let ty = CType(cxType: cxt) else {
            unhandledKind(cxt.kind)
          }
          return ty
        }
        if cxType.kind == CXType_FunctionProto {
          self = .FunctionProto(callingConv: callingConv, args: argTypes, result: resultType)
        } else {
          self = .FunctionNoProto(callingConv: callingConv, args: argTypes, result: resultType)
        }
      case CXType_Elaborated:
        let parts = cxType.spelling!.split(separator: " ")
        self = .Elaborated(name: parts.last!, prefix: parts.count > 1 ? parts[0..<parts.count-1].joined(separator: " "): nil)
      case CXType_ConstantArray:
        guard let type = CType(cxType: clang_getArrayElementType(cxType)) else {
          unhandledKind(clang_getArrayElementType(cxType).kind)
        }
        let size: Int64 = clang_getArraySize(cxType)
        self = .ConstantArray(type: type, size: size)
      default:
        return nil
    }
  }
}
