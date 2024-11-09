struct LanguageParser {
  static func parse(language: Language, config: ParseConfiguration) throws -> OctoLibrary {
    switch (language) {
      case .c:
        return try Self.parseC(config: config)
      default:
        fatalError("Unimplemented language \(language)")
    }
  }
}
