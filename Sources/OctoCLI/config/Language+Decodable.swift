import OctoIntermediate
import ArgumentParser

extension Language: Decodable, CodingKey, ExpressibleByArgument {
  public init(from decoder: Decoder) throws {
    let valueContainer = try decoder.singleValueContainer()
    let stringValue = try valueContainer.decode(String.self)
    self = Language(fromString: stringValue)
  }

  public init?(argument: String) {
    self = Language(fromString: argument)
  }

  public init?(stringValue: String) {
    self = Language(fromString: stringValue)
  }

  public var stringValue: String {
    self.description.lowercased()
  }

  public init?(intValue: Int) { nil }

  public var intValue: Int? { nil }
}
