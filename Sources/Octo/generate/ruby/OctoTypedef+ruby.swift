extension OctoTypedef {
  func rubyGenerateFFI(in lib: OctoLibrary, options: GenerationOptions) -> String {
    guard let refersTo = self.refersTo.rubyTypeDef else {
      fatalError("[\(self.origin)] ERROR: could not create ruby type for typedef \(self.name) = \(self.refersTo)")
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
