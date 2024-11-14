extension OctoUserType {
  func rubyGenerateFFI(in lib: OctoLibrary, options: GenerationOptions) -> String {
    switch (self.inner) {
      case .record(let record):
        return record.rubyGenerateFFI(in: lib, options: options)
      case .`enum`(let e):
        return e.rubyGenerateFFI(in: lib, options: options)
    }
  }

  func rubyGenerateModule(in lib: OctoLibrary, options: GenerationOptions, ffiModuleName: String) throws -> String {
    switch (self.inner) {
      case .record(let record):
        return try record.rubyGenerateModule(in: lib, options: options, ffiModuleName: ffiModuleName)
      case .`enum`(let e):
        return e.rubyGenerateModule(in: lib, options: options, ffiModuleName: ffiModuleName)
    }
  }
}
