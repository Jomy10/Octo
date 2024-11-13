import Octo

extension Octo {
  mutating func run() throws {
    try self.initArgs()

    if self.verbose {
      setOctoLogLevel(.info)
    }
    if self.veryVerbose {
      setOctoLogLevel(.debug)
    }

    // Parse //
    let languageSpecificConfig: ParseConfiguration.LanguageSpecificConfiguration
    switch (self.args.inputLanguage) {
      case .c:
        languageSpecificConfig = .c(ParseConfiguration.CConfig(
          headerFile: self.args.inputLocation,
          clangFlags: self.args.cIn_clangFlags,
          includeHeaders: self.args.cIn_includeHeaders,
          logLevel: self.args.cIn_logLevel ?? .note,
          errorLevel: self.args.cIn_errorLevel ?? .error
        ))
      default:
        fatalError("Parsing of language \(self.args.inputLanguage) is not yet supported")
    }
    let parseConfig = ParseConfiguration(
      outputLibraryName: self.args.outputLibraryName,
      outputLocation: self.args.outputLocation,
      languageSpecificConfig: languageSpecificConfig
    )

    var library = try LanguageParser.parse(language: self.args.inputLanguage, config: parseConfig)
    defer { library.destroy() }

    let attributesEnumerated: EnumeratedSequence<[Attribute]> = self.args.attributes.enumerated()
    for (i, attribute) in attributesEnumerated {
      guard let objectId = library.getObject(name: String(attribute.symbolName)) else {
        // TODO: replace with throw
        fatalError("Symbol '\(attribute.symbolName)' doesn't exist (passed as argument to --argument)")
      }
      library.addAttribute(to: objectId, attribute.asOctoAttribute, id: OctoLibrary.LangId.arg(i))
    }

    // Generate code //
    let generationOptions = GenerationOptions(
      indent: self.args.indent,
      libs: self.args.linkLibs
    )
    let code = CodeGenerator.generate(language: self.args.outputLanguage, lib: library, options: generationOptions)

    try code.write(to: self.args.outputLocation)
  }
}
