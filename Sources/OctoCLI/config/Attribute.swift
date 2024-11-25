import OctoIO
import ArgumentParser
import OctoIntermediate

struct Attribute: Decodable, ExpressibleByArgument {
  let symbolName: String
  let attributeName: String
  let arguments: [String]

  struct AttributeError: Error, CustomStringConvertible {
    let message: String

    init(_ message: String) {
      self.message = message
    }

    var description: String {
      "Error parsing attribute: " + self.message
    }
  }

  init?(argument: String) {
    let s = argument.split(separator: ">", maxSplits: 1)
    if s.count != 2 {
      print("Malformed argument (expected '>'): \(argument)", to: .stderr)
      return nil
    }
    self.symbolName = String(s[0])
    let s2 = s[1].split(separator: "=", maxSplits: 1)
    self.attributeName = String(s2[0])
    if let argumentArgs = s2.get(1) {
      let args = argumentArgs.split(separator: ",").map { String($0) }
      self.arguments = args
    } else {
      self.arguments = []
    }
  }

  enum CodingKeys: String, CodingKey {
    case symbolName = "symbol"
    case attributeName = "attribute"
    case arguments
  }

  //init(from decoder: Decoder) throws {
  //  let container = try decoder.container(keyedBy: CodingKeys.self)
  //  let symbolName = try container.decode(String.self, forKey: .symbol)
  //  self.symbolName = symbolName[symbolName.startIndex..<symbolName.endIndex]
  //  let arguments = try container.decode([String].self, forKey: .args)
  //  if arguments.count == 0 {
  //    throw AttributeError("An attribute's arguments should have at least one argument")
  //  }
  //  self.attributeName = arguments[0][arguments[0].startIndex..<arguments[1].endIndex]
  //  if arguments.count > 1 {
  //    self.arguments = arguments[1...].map { $0[$0.startIndex..<$0.endIndex] }
  //  } else {
  //    self.arguments = []
  //  }
  //}

  func toOctoAttribute(in lib: OctoLibrary) throws -> OctoAttribute {
    guard let octoAttribute = try OctoAttribute(
      name: self.attributeName,
      params: self.arguments.map { .string($0) },
      in: lib,
      origin: .argument // TODO: argument or TOML file location
    ) else {
      throw AttributeError("Invalid attribute name \(self.attributeName)")
    }
    return octoAttribute
  }
}
