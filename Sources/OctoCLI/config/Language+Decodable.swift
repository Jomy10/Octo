import OctoIntermediate
import ArgumentParser

extension Language: Decodable, CodingKey, ExpressibleByArgument {
  public init(from decoder: Decoder) throws {
    let valueContainer = try decoder.singleValueContainer()
    let stringValue = try valueContainer.decode(String.self)
    self = try Language(fromString: stringValue)
  }

  public init?(argument: String) {
    if let language = try? Language(fromString: argument) {
      self = language
    } else {
      return nil
    }
  }

  init(fromString stringValue: String) throws {
    switch (stringValue) {
      case "c": self = .c
      case "cxx": fallthrough
      case "c++": fallthrough
      case "cpp": self = .cxx
      case "swift": self = .swift
      case "rust": self = .rust
      case "rb": fallthrough
      case "ruby": self = .ruby
      default: throw ConfigError("Invalid language '\(stringValue)'")
    }
  }
}
