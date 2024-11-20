extension OctoType {
  /// Ruby type representation when inside of a definition
  var rubyTypeDef: String? {
    self.rubyTypeGet(isDefinition: true)
  }

  /// Ruby type definition when creating a new type (for user types and pointers)
  var rubyType: String? {
    self.rubyTypeGet(isDefinition: false)
  }

  private func rubyTypeGet(isDefinition: Bool) -> String? {
    switch (self.kind) {
      case .Void: return ":void"
      case .Bool: return ":bool"
      case .U8: return ":uchar"
      case .S8: return ":char"
      case .WChar:
        switch (self.size) {
          case 8 / 8: return ":uchar"
          case 16 / 8: return ":uint16"
          case 32 / 8: return ":uint32"
          case 64 / 8: return ":uint64"
          default: return nil
        }
      case .U16: return ":uint16"
      case .S16: return ":int16"
      case .U32: return ":uint32"
      case .S32: return ":int32"
      case .U64: return ":uint64"
      case .S64: return ":int64"
      case .U128: fallthrough
      case .S128: return nil
      case .F32: return ":float"
      case .F64: return ":double"
      case .FLong: return ":long_double"
      case .Pointer(to: let pointeeType):
        switch (pointeeType.kind) {
          case .UserDefined(name: let name, id: _):
            // TODO: !!
            //if let id = lid {

            //} else {
              return "\(name)\(isDefinition ? ".ptr" : "")"
            //}
          default: return ":pointer"
        }
      case .Function(callingConv: let callingConv, args: _, result: _):
        if callingConv != .c { return ":pointer" }
        return ":pointer"
      case .ConstantArray(type: _, size: _):
        return ":pointer"
      case .UserDefined(name: let name, id: _): // TODO: use id!
        return "\(name)\(isDefinition ? ".val" : "")"
    }
  }
}
