extension OctoTypedef {
  func rubyGenerateFFI(in lib: OctoLibrary, options: GenerationOptions) throws -> String {
    guard let refersTo = self.refersTo.rubyTypeDef else {
      throw GenerationError("could not create ruby type for typedef \(self.name) = \(self.refersTo)", .ruby, self.origin)
    }

    return """
    \(self.rubyFFIName) = \(refersTo)
    """
  }

  func rubyGenerateModule(in lib: OctoLibrary, options: GenerationOptions, ffiModuleName: String) -> String {
    // TODO: if points to record -> typedef to module class
    """
    \(self.rubyName) = \(ffiModuleName)::\(self.rubyFFIName)
    """
  }

  var rubyFFIName: String {
    rubyConstantName(of: self.name)
  }

  var rubyName: String {
    rubyConstantName(of: self.bindingName)
  }
}
