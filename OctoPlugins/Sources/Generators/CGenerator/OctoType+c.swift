import OctoIntermediate
import OctoGenerateShared

/// Construct a type
fileprivate func ctype(_ s: String?...) -> String {
  s.filter { $0 != nil }.map { $0! }.joined(separator: " ")
}

extension OctoType {
  func cType(options: GenerationOptions, name: String? = nil, isRecordField: Bool = false) -> String {
    //"\(self.mutable ? "" : "const ")\(self.optional ? "__attribute__((nullable)) " : "__attribute__((nonnull)) ")\(self.kind.cType(options: options))"

    let constQual: String? = self.mutable ? nil : "const"
    let optionalQual = self.optional ? nil : (isRecordField ? "__attribute__((annotate(\"nonnull\")))" : "__attribute__((nonnull))")
    let ty = {
      switch (self.kind) {
        case .Void: return "void"
        case .Bool: return "bool"
        case .I8: return "int8_t"
        case .I16: return "int16_t"
        case .I32: return "int32_t"
        case .I64: return "int64_t"
        case .I128: return "int128_t"
        case .ISize: return "intptr_t"
        case .U8: return "uint8_t"
        case .U16: return "uint16_t"
        case .U32: return "uint32_t"
        case .U64: return "uint64_t"
        case .U128: return "uint128_t"
        case .USize: return "uintptr_t"
        case .IntLeast(size: let size, sizeOnCurrentPlatform: _): return "int_least\(size)_t"
        case .UIntLeast(size: let size, sizeOnCurrentPlatform: _): return "uint_least\(size)_t"
        case .IntFast(size: let size, sizeOnCurrentPlatform: _): return "int_fast\(size)_t"
        case .UIntFast(size: let size, sizeOnCurrentPlatform: _): return "uint_fast\(size)_t"
        case .IntMax(sizeOnCurrentPlatform: _): return "intmax_t"
        case .UIntMax(sizeOnCurrentPlatform: _): return "uintmax_t"
        case .F32: return "float"
        case .F64: return "double"
        case .FLong: return "long double"
        case .Char8: return "char"
        case .UnicodeScalar(bitCharSize: let bitCharSize):
          if let bitCharSize = bitCharSize {
            return "_char\(bitCharSize)_t"
          } else {
            return "wchar_t"
          }
        case .UnicodeCString(scalarTypeSize: let size):
          return ctype(optionalQual, "_char\(size)_t*")
        case .CString: return ctype(optionalQual, "char*")
        case .Pointer(to: let pointeeType):
          return "\(pointeeType.cType(options: options))*"
        case .Function(callingConv: let callingConv, args: let args, result: let res):
          // TODO: calling convention
          _ = callingConv
          return ctype(optionalQual, "\(res.cType(options: options))(*\(name == nil ? "" : name!))(\(args.map { $0.cType(options: options) }.joined(separator: ", ")))")
        case .ConstantArray(type: let type, size: let size):
          return ctype(optionalQual, "\(type.cType(options: options))\(name == nil ? "" : name!)[\(size)]")
        case .Record(let record):
          let recordType: String
          switch (record.type) {
            case .taggedUnion: fallthrough
            case .`struct`: recordType = "struct"
            case .union: recordType = "union"
          }
          return "\(recordType) _\(record.ffiName!)"
        case .Enum(let e):
          return "enum _\(e.ffiName!)"
      }
    }()

    var ext = ""
    if let name = name {
      switch (self.kind) {
        case .Function: fallthrough
        case .ConstantArray:
          break
        default:
          ext = " \(name)"
      }
    }

    return ctype(constQual, ty) + ext
  }
}
