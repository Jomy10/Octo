import Octo

extension Octo {
  mutating func run() throws {
    if self.verbose {
      setOctoLogLevel(.info)
    }
    if self.veryVerbose {
      setOctoLogLevel(.debug)
    }

    // Parse //
    let languageSpecificConfig: ParseConfiguration.LanguageSpecificConfiguration
    switch (self.inputLanguage) {
      case .c:
        languageSpecificConfig = .c(ParseConfiguration.CConfig(
          headerFile: self.inputLocation,
          clangFlags: self.cIn_clangFlags,
          includeHeaders: self.cIn_includeHeaders,
          logLevel: self.cIn_logLevel ?? .note,
          errorLevel: self.cIn_errorLevel ?? .error
        ))
      default:
        fatalError("Parsing of language \(self.inputLanguage) is not yet supported")
    }
    let parseConfig = ParseConfiguration(
      outputLibraryName: self.outputLibraryName,
      outputLocation: self.outputLocation,
      languageSpecificConfig: languageSpecificConfig
    )

    var library = try LanguageParser.parse(language: self.inputLanguage, config: parseConfig)
    defer { library.destroy() }

    for (i, attribute) in self.attributes.enumerated() {
      guard let objectId = library.getObject(name: String(attribute.symbolName)) else {
        // TODO: replace with throw
        fatalError("Symbol '\(attribute.symbolName)' doesn't exist (passed as argument to --argument)")
      }
      library.addAttribute(to: objectId, attribute.asOctoAttribute, id: OctoLibrary.LangId.arg(i))
    }

    // Generate code //
    let generationOptions = GenerationOptions(
      indent: self.indent,
      libs: self.linkLibs
    )
    let code = CodeGenerator.generate(language: self.outputLanguage, lib: library, options: generationOptions)

    try code.write(to: self.outputLocation)
  }
}
