import ExpressionInterpreter

public struct ParseConfiguration {
  public let languageSpecificConfig: LanguageSpecificConfiguration
  public let renameOperations: [Program]

  public init(
    languageSpecificConfig: LanguageSpecificConfiguration,
    renameOperations: [Program]
  ) {
    self.languageSpecificConfig = languageSpecificConfig
    self.renameOperations = renameOperations
  }

  public enum LanguageSpecificConfiguration {
    case c(CConfig)
  }
}
