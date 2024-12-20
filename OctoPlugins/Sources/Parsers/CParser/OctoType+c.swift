import OctoIntermediate
import Clang
import OctoParseTypes

// TODO: https://clang.llvm.org/doxygen/group__CINDEX__TYPES.html#ga8adac28955bf2f3a5ab1fd316a498334
//  -> clang_getUnqualifiedType() gets the type of a typedef
extension OctoType {
  init(
    cxType: CXType,
    in lib: OctoLibrary,
    origin: OctoOrigin? = nil
  ) throws {
    let kind: OctoType.Kind = try OctoType.Kind(cxType: cxType, in: lib, origin: origin)
    self.init(cxType: cxType, kind: kind, origin: origin)
  }

  init(cxType: CXType, kind: OctoType.Kind, origin: OctoOrigin? = nil) {
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
  init(cxType: CXType, in lib: OctoLibrary, origin: OctoOrigin? = nil) throws {
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
            throw ParseError("Invalid length for unsigned integer variant \(cxType.size) bytes", origin: origin)
        }
      case CXType_Char_S: fallthrough
      case CXType_SChar:
        self = .Char8
      case CXType_Short: fallthrough
      case CXType_Int: fallthrough
      case CXType_Long: fallthrough
      case CXType_LongLong: fallthrough
      case CXType_Int128:
        switch (Int(cxType.size)) {
          case 8 / 8: self = .I8
          case 16 / 8: self = .I16
          case 32 / 8: self = .I32
          case 64 / 8: self = .I64
          case 128 / 8: self = .I128
          default:
            throw ParseError("Invalid length for signed integer variant \(cxType.size) bytes", origin: origin)
        }
      case CXType_Float: self = .F32
      case CXType_Double: self = .F64
      case CXType_LongDouble: self = .FLong
      case CXType_Pointer:
        let type = try OctoType(cxType: cxType.pointeeType, in: lib)
        switch (type.kind) {
          case .UnicodeScalar(bitCharSize: let size):
            self = .UnicodeCString(scalarTypeSize: size!)
          case .Char8:
            self = .CString
          default:
            self = .Pointer(to: type)
        }
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
            if let object = lib.getObject(forRef: cursor) as? OctoRecord {
              self = .Record(object)
            } else {
              guard let object = lib.getObject(byName: cursor.spelling!) as? OctoRecord else {
                throw ParseError("Object \(cursor.spelling!) is not a record or doesn't exist", origin: origin)
              }
              self = .Record(object)
            }
          case CXCursor_EnumDecl:
            if let object = lib.getObject(forRef: cursor) as? OctoEnum {
              self = .Enum(object)
            } else {
              guard let object = lib.getObject(byName: cursor.spelling!) as? OctoEnum else {
                throw ParseError("Object \(cursor.spelling!) is not an enum or doesn't exist", origin: origin)
              }
              self = .Enum(object)
            }
          case CXCursor_TypedefDecl:
            if let obj = lib.getObject(forRef: cursor.typedefDeclUnderlyingType.typeDeclaration) {
              if let obj = obj as? OctoRecord {
                self = .Record(obj)
              } else if let obj = obj as? OctoEnum {
                self = .Enum(obj)
              } else {
                throw ParseError("Object cannot be typedef'd \(obj)", origin: origin)
              }
            } else if let type = lib.getType(byName: cxType.spelling!) {
              self = type.kind
            } else {
              guard let type = Self.systemTypedef(cxType: cxType, name: cursor.spelling!) else {
                throw ParseError("Object \(cursor.spelling!) is not a typedef or doesn't exist", origin: origin)
              }
              self = type
            }
          default: throw ParseError("Unhandled elaborated type \(cursor.kind)", origin: origin)
        }
      case CXType_ConstantArray:
        let type = try OctoType(cxType: cxType.arrayElementType, in: lib)
        let size: Int64 = cxType.arraySize
        self = .ConstantArray(type: type, size: size)
      default:
        throw ParseError.unhandledKind(cxType.kind, origin: origin)
    }
  }

  static func systemTypedef(cxType: CXType, name: String) -> OctoType.Kind? {
    switch (name) {
      case "size_t": return .USize
      case "intptr_t": return .ISize
      case "uintptr_t": return .USize
      case "intmax_t": return .IntMax(sizeOnCurrentPlatform: Int(cxType.size))
      case "uintmax_t": return .UIntMax(sizeOnCurrentPlatform: Int(cxType.size))
      case "uint8_t": return .U8
      case "uint16_t": return .U16
      case "uint32_t": return .U32
      case "uint64_t": return .U64
      case "uint128_t": return .U128
      case "int8_t": return .I8
      case "int16_t": return .I16
      case "int32_t": return .I32
      case "int64_t": return .I64
      case "int128_t": return .I128
      case "char8_t": return .UnicodeScalar(bitCharSize: 8)
      case "char16_t": return .UnicodeScalar(bitCharSize: 16)
      case "char32_t": return .UnicodeScalar(bitCharSize: 32)
      case "wchar_t": return .UnicodeScalar(bitCharSize: Int(cxType.size))
      case "int_least8_t": return .IntLeast(size: 8, sizeOnCurrentPlatform: Int(cxType.size))
      case "int_least16_t": return .IntLeast(size: 16, sizeOnCurrentPlatform: Int(cxType.size))
      case "int_least32_t": return .IntLeast(size: 32, sizeOnCurrentPlatform: Int(cxType.size))
      case "int_least64_t": return .IntLeast(size: 64, sizeOnCurrentPlatform: Int(cxType.size))
      case "uint_least8_t": return .UIntLeast(size: 8, sizeOnCurrentPlatform: Int(cxType.size))
      case "uint_least16_t": return .UIntLeast(size: 16, sizeOnCurrentPlatform: Int(cxType.size))
      case "uint_least32_t": return .UIntLeast(size: 32, sizeOnCurrentPlatform: Int(cxType.size))
      case "uint_least64_t": return .UIntLeast(size: 64, sizeOnCurrentPlatform: Int(cxType.size))
      default: return nil
    }
  }

  var isCPointer: Bool {
    switch (self) {
      case .Pointer: fallthrough
      case .CString: fallthrough
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
      default: throw ParseError("unimplemented calling convention \(cxCallingConv)")
    }
  }
}
