import OctoIntermediate
import OctoGenerateShared

/// Construct a type
fileprivate func ctype(_ s: String?...) -> String {
  s.filter { $0 != nil }.map { $0! }.joined(separator: " ")
}

extension OctoType {
  func cType(options: GenerationOptions, name: String? = nil) -> String {
    //"\(self.mutable ? "" : "const ")\(self.optional ? "__attribute__((nullable)) " : "__attribute__((nonnull)) ")\(self.kind.cType(options: options))"

    let constQual: String? = self.mutable ? nil : "const"
    let optionalQual = self.optional ? nil : "__attribute__((nonnull))"
    let ty = {
      switch (self.kind) {
        case .Void: return "void"
        case .Bool: return "bool"
        case .I8: return "int8_t"
        case .I16: return "int16_t"
        case .I32: return "int32_t"
        case .I64: return "int64_t"
        case .I128: return "int128_t"
        case .U8: return "uint8_t"
        case .U16: return "uint16_t"
        case .U32: return "uint32_t"
        case .U64: return "uint64_t"
        case .U128: return "uint128_t"
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
        case .CString: return ctype(optionalQual, "char*")
        case .Pointer(to: let pointeeType):
          return "\(pointeeType.cType(options: options))"
        case .Function(callingConv: let callingConv, args: let args, result: let res):
          // TODO: calling convention
          _ = callingConv
          return ctype(optionalQual, "\(res.cType(options: options))(*\(name == nil ? "" : name!))(\(args.map { $0.cType(options: options) }.joined(separator: ", ")))")
        case .ConstantArray(type: let type, size: let size):
          return ctype(optionalQual, "\(type.cType(options: options))\(name == nil ? "" : name!)[\(size)]")
        case .Record(let record):
          return "struct \(record.cRecordName(options: options))"
        case .Enum(let e):
          return "enum \(e.cEnumName(options: options))"
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
