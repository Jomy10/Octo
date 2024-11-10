extension OctoEnum {
  func rubyGenerateFFI(in lib: OctoLibrary, options: GenerationOptions) -> String {
    """
    \(self.rubyFFIName) = enum \(self.cases.map { caseId in
      lib.getEnumCase(id: caseId)!
    }.map { enumCase in
      "\(enumCase.rubyName), \(enumCase.value.stringValue)"
    }.joined(separator: "\(String(repeating: " ", count: "enum ".count))"))
    """
  }

  func rubyGenerateModule(in lib: OctoLibrary, options: GenerationOptions, ffiModuleName: String) -> String {
    ""
  }

  var rubyFFIName: String {
    rubyConstantName(of: self.name)
  }

  var rubyName: String {
    rubyConstantName(of: self.bindingName)
  }
}

extension OctoEnumCase {
  var rubyName: String {
    rubyConstantName(of: self.bindingName)
  }
}
