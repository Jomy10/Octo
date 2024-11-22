import ExpressionInterpreter

public struct ParseConfiguration {
  public let outputLibraryName: String
  public let languageSpecificConfig: LanguageSpecificConfiguration
  public let renameOperations: [Program]

  public enum LanguageSpecificConfiguration {
    case c(CConfig)
  }
}
