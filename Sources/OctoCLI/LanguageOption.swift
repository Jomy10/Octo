import Octo
import ArgumentParser

struct LanguageOption: Equatable, Hashable, ExpressibleByArgument {
  let language: Language
  let name: String
  let value: Substring?

  enum ParseError: Swift.Error, CustomStringConvertible {
    case malformed(String)
    case invalidLanguage(Substring)

    var description: String {
      switch (self) {
        case .malformed(let arg):
          return "Malformed language option '\(arg)' (format: <lang>:<opt>[=val])"
        case .invalidLanguage(let lang):
          return "Invalid language \(lang)"
      }
    }
  }

  static func parse(_ opt: String) throws -> Self {
    let s1: [Substring] = opt.split(separator: ":", maxSplits: 1)
    guard s1.count == 2 else {
      throw Self.ParseError.malformed(opt)
    }

    guard let language = Language(argument: String(s1[0])) else {
      throw Self.ParseError.invalidLanguage(s1[0])
    }

    let s2: [Substring] = s1[1].split(separator: "=", maxSplits: 1)

    let optName = s2[0]
    let optValue = s2.last

    return Self(
      language: language,
      name: optName,
      value: optValue
    )
  }

  private init(
    language: Language,
    name: some StringProtocol,
    value: Substring?
  ) {
    self.language = language
    self.name = String(name)
    self.value = value
  }

  public init?(argument: String) {
    do {
      self = try Self.parse(argument)
    } catch let error {
      print(error) // TODO: OctoLog
      return nil
    }
  }
}
