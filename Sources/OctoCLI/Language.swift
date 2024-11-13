import Octo
import ArgumentParser

extension Language: ExpressibleByArgument {
  public init?(argument: String) {
    switch (argument.lowercased()) {
      case "c": self = .c
      case "cxx": fallthrough
      case "c++": fallthrough
      case "cpp": self = .cxx
      case "swift": self = .swift
      case "ruby": fallthrough
      case "rb": self = .ruby
      case "rust": fallthrough
      case "rs": self = .rust
      default: return nil
    }
  }
}

extension Language: Decodable {
  enum DecodingError: Swift.Error {
    case languageNotValid(language: String)
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer()
    let stringValue = try value.decode(String.self)
    guard let language = Self(argument: stringValue) else {
      throw Self.DecodingError.languageNotValid(language: stringValue)
    }
    self = language
  }
}
