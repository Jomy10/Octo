import OctoIntermediate

extension OctoConfig {
  init(fromArguments args: OctoManualArguments) throws {
    self.outputLibraryName = args.outputLibraryName!
    self.link = args.link

    self.inputLanguage = args.inputLanguage!
    self.inputLocation = args.inputLocation!
    self.langInOpts = try LanguageInputOptions.parse(arguments: args.langInOpts, language: self.inputLanguage)
    self.attributes = args.attributes

    self.outputOptions = [
      args.outputLanguage! : try OutputOptions(fromArguments: args, language: args.outputLanguage!)
    ]

    self.renameOperations = []
  }
}

extension OctoConfig.OutputOptions {
  init(fromArguments args: OctoManualArguments, language: Language) throws {
    self.outputLocation = args.outputLocation!
    self.langOutOpts = try LanguageOutputOptions.parse(arguments: args.langOutOpts, language: language)
    self.indentCount = args.indentCount ?? 2
    self.indentType = args.indentType ?? .spaces
    self.renameOperations = []
  }
}
