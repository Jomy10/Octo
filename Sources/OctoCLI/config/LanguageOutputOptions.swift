import OctoIntermediate

protocol LanguageOutputOptionSet {}

struct LanguageOutputOptions {
  static func decode(
    _ container: KeyedDecodingContainer<OctoConfig.OutputOptions.OutputCodingKeys>,
    language: Language
  ) throws -> (any LanguageOutputOptionSet)? {
    switch (language) {
      case .c: return try container.decodeIfPresent(Self.C.self, forKey: .langOutOpts)
      case .ruby: return try container.decodeIfPresent(Self.Ruby.self, forKey: .langOutOpts)
      default: throw ConfigError("Unimplemented output language \(language)")
    }
  }

  static func parse(
    arguments args: [String],
    language: Language
  ) throws -> (any LanguageOutputOptionSet)? {
    let args = args.map { arg in
      arg.split(separator: "=")
    }

    switch (language) {
      case .c: return try Self.C(fromArguments: args)
      case .ruby: return try Self.Ruby(fromArguments: args)
      default: throw ConfigError("Unimplemented input language \(language)")
    }
  }

  struct C: Decodable, LanguageOutputOptionSet {
    init(fromArguments args: [[Substring]]) throws {
    }
  }

  struct Ruby: Decodable, LanguageOutputOptionSet {
    init(fromArguments args: [[Substring]]) throws {
    }
  }
}
