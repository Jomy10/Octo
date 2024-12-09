import OctoIntermediate
import OctoGenerateShared

extension OctoTypedef: RubyCodeGenerator {
  func generateRubyFFICode(
    options: GenerationOptions,
    in lib: OctoLibrary
  ) throws -> String {
    ""
  }

  func generateRubyBindingCode(
    options: GenerationOptions,
    in lib: OctoLibrary,
    ffiModuleName: String
  ) throws -> String {
    if self.refersTo.isUserType {
      let rName: String
      switch (self.refersTo.kind) {
        case .Record(let record): rName = record.rubyName
        case .Enum(let e): rName = e.rubyName
        case .Pointer(to: let ptype):
          switch (ptype.kind) {
            case .Record(let record): rName = record.rubyName
            case .Enum(let e): rName = e.rubyName
            default: return ""
          }
        default: return ""
      }

      // Name already exists => Skip typedef
      if rName == self.rubyName {
        return ""
      }

      return """
      \(self.rubyName) = \(rName)
      """
    } else {
      return ""
    }
  }

  var rubyName: String {
    rubyConstantName(of: self.bindingName!)
  }
}
