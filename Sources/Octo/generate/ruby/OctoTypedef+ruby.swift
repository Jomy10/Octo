extension OctoTypedef {
  func rubyGenerateFFI(in lib: OctoLibrary, options: GenerationOptions) -> String {
    """
    \(self.rubyFFIName) = \(self.refersTo.rubyTypeDef!)
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
