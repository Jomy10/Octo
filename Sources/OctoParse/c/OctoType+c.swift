import OctoIntermediate
import OctoIO
import Clang

// TODO: https://clang.llvm.org/doxygen/group__CINDEX__TYPES.html#ga8adac28955bf2f3a5ab1fd316a498334
//  -> clang_getUnqualifiedType() gets the type of a typedef
extension OctoType {
  init(
    cxType: CXType,
    in lib: OctoLibrary
  ) throws {
    let kind = try OctoType.Kind(cxType: cxType, in: lib)
    self.init(cxType: cxType, kind: kind)
  }

  init(cxType: CXType, kind: OctoType.Kind) {
    // TODO: get rid of nullability attributes and rely on this function?
    let nullability = clang_Type_getNullability(cxType)
    self.init(
      kind: kind,
      optional: nullability == CXTypeNullability_NullableResult || nullability == CXTypeNullability_Nullable || ((nullability == CXTypeNullability_Unspecified || nullability == CXTypeNullability_Invalid) && kind.isCPointer),
      mutable: !cxType.isConstQualifiedType
    )
  }
}

extension OctoType.Kind {
  init(cxType: CXType, in lib: OctoLibrary) throws {
    switch (cxType.kind) {
      case CXType_Void: self = .Void
      case CXType_Bool: self = .Bool
      case CXType_Char16: self = .UnicodeScalar(bitCharSize: 16)
      case CXType_Char32: self = .UnicodeScalar(bitCharSize: 32)
      case CXType_WChar: self = .UnicodeScalar(bitCharSize: Int(cxType.size))
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
            throw ParseError("Invalid length for unsigned integer variant \(cxType.size) bytes")
        }
      case CXType_Char_S: fallthrough
      case CXType_SChar: fallthrough
      case CXType_Short: fallthrough
      case CXType_Int: fallthrough
      case CXType_Long: fallthrough
      case CXType_LongLong: fallthrough
      case CXType_Int128:
        switch (cxType.size) {
          case 8 / 8: self = .I8
          case 16 / 8: self = .I16
          case 32 / 8: self = .I32
          case 64 / 8: self = .I64
          case 128 / 8: self = .I128
          default:
            throw ParseError("Invalid length for signed integer variant \(cxType.size) bytes")
        }
      case CXType_Float: self = .F32
      case CXType_Double: self = .F64
      case CXType_LongDouble: self = .FLong
      case CXType_Pointer:
        let type = try OctoType(cxType: cxType.pointeeType, in: lib)
        self = .Pointer(to: type)
      case CXType_FunctionProto: fallthrough
      case CXType_FunctionNoProto:
        let resultType = try OctoType(cxType: cxType.resultType, in: lib)
        let callingConv = try OctoCallingConv(cxCallingConv: cxType.functionTypeCallingConv)
        let argTypes = try cxType.argTypes.map { cxt in try OctoType(cxType: cxt, in: lib) }
        self = .Function(callingConv: callingConv, args: argTypes, result: resultType)
      case CXType_Elaborated:
        let cursor = cxType.typeDeclaration
        switch (cursor.kind) {
          case CXCursor_StructDecl: fallthrough
          case CXCursor_UnionDecl:
            guard let object = lib.getObject(forRef: cursor) as? OctoRecord else {
              throw ParseError("Object \(cursor.spelling!) is not a record or doesn't exist")
            }
            self = .Record(object)
          case CXCursor_EnumDecl:
            guard let object = lib.getObject(forRef: cursor) as? OctoEnum else {
              throw ParseError("Object \(cursor.spelling!) is not an enum or doesn't exist")
            }
            self = .Enum(object)
          case CXCursor_TypedefDecl:
            guard let object = lib.getObject(forRef: cursor) as? OctoTypedef else {
              throw ParseError("Object \(cursor.spelling!) is not a typedef or doesn't exist")
            }
            // TODO: mutability and optional?
            self = object.refersTo.kind
          default: throw ParseError("Unhandled elaborated type \(cursor.kind)")
        }
      case CXType_ConstantArray:
        let type = try OctoType(cxType: cxType.arrayElementType, in: lib)
        let size: Int64 = cxType.arraySize
        self = .ConstantArray(type: type, size: size)
      default:
        throw ParseError.unhandledKind(cxType.kind)
    }
  }

  var isCPointer: Bool {
    switch (self) {
      case .Pointer: fallthrough
      case .Function: return true
      default: return false
    }
  }
}

extension OctoCallingConv {
  init(cxCallingConv: CXCallingConv) throws {
    switch (cxCallingConv) {
      //case CXCallingConv_Default: self = .`default`
      case CXCallingConv_C: self = .c
      case CXCallingConv_Swift: self = .swift
      //case CXCallingConv_SwiftAsync: self = .swiftAsync
      //case CXCallingConv_Win64: self = .win64
      //case CXCallingConv_Invalid: self = .invalid
      default: throw ParseError("unimplemented")
    }
  }
}
