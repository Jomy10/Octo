import ExpressionInterpreter

public struct ParseConfiguration {
  public let outputLibraryName: String
  public let languageSpecificConfig: LanguageSpecificConfiguration
  public let renameOperations: [Program]

  public init(
    outputLibraryName: String,
    languageSpecificConfig: LanguageSpecificConfiguration,
    renameOperations: [Program]
  ) {
    self.outputLibraryName = outputLibraryName
    self.languageSpecificConfig = languageSpecificConfig
    self.renameOperations = renameOperations
  }

  public enum LanguageSpecificConfiguration {
    case c(CConfig)
  }
}
