import OctoIntermediate
import OctoGenerateShared

extension OctoType {
  /// Ruby type definition
  func rubyFFIType() throws -> String {
    switch (self.kind) {
      case .Void: return ":void"
      case .Bool: return ":bool"
      case .U8: return ":uchar"
      case .Char8: fallthrough
      case .I8: return ":char"
      case .UnicodeScalar(bitCharSize: let bitSize):
        switch (bitSize) {
          case 8: return ":char"
          case 16: return ":int16"
          case 32: return ":int32"
          default: return ":int64"
        }
      case .U16: return ":uint16"
      case .I16: return ":int16"
      case .U32: return ":uint32"
      case .I32: return ":int32"
      case .U64: return ":uint64"
      case .I64: return ":int64"
      case .I128: throw UnsupportedType(language: .ruby, type: self)
      case .U128: throw UnsupportedType(language: .ruby, type: self)
      case .F32: return ":float"
      case .F64: return ":double"
      case .FLong: return ":long_double"
      case .CString:
        if self.mutable {
          return ":pointer"
        } else {
          return ":string"
        }
      case .Pointer(to: let type):
        switch (type.kind) {
          case .Enum(let e):
            return "\(rubyConstantName(of: e.ffiName!)).ptr"
          case .Record(let record):
            return "\(rubyConstantName(of: record.ffiName!)).ptr"
          default:
            return ":pointer"
        }
      case .Function: return ":pointer"
      case .ConstantArray(type: let type, size: _):
        return try OctoType(
          kind: .Pointer(to: type),
          optional: false,
          mutable: false
        ).rubyFFIType()
      case .Record(let record):
        return "\(rubyConstantName(of: record.ffiName!)).val"
      case .Enum(let e):
        return rubyConstantName(of: e.ffiName!)
    }
  }

  /// C to ruby type
  func cToRuby(_ param: String) -> String {
    switch (self.kind) {
      case .Record(let record): return record.cToRuby(param)
      case .Enum(let e): return e.cToRuby(param)
      case .Pointer(to: let t):
        switch (t.kind) {
          case .Record(let record): return record.cToRuby(param)
          case .Enum(let e): return e.cToRuby(param)
          default: return param
        }
      default: return param
    }
  }

  /// Ruby to C type
  func rubyToC(_ param: String) -> String {
    switch (self.kind) {
      case .Record(let record): return record.rubyToC(param)
      case .Enum(let e): return e.rubyToC(param)
      case .Pointer(to: let t):
        switch (t.kind) {
          case .Enum(let e): return e.rubyToC(param)
          case .Record(let record): return record.rubyToC(param)
          default: return param
        }
      default: return param
    }
  }
}
