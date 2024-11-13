import Octo
import OctoIO
import ArgumentParser

struct Attribute: Equatable, ExpressibleByArgument {
  let symbolName: Substring
  let attributeName: Substring
  let arguments: [Substring]
  let origin: OctoOrigin

  enum ParseError: Swift.Error, CustomStringConvertible {
    case malformed(String)

    var description: String {
      switch (self) {
        case .malformed(let attr): return "Malformed attribute value '\(attr)'"
      }
    }
  }

  static func parse(_ attr: String) throws -> Attribute {
    let s1: [Substring] = attr.split(separator: ">", maxSplits: 1)
    if s1.count != 2 { throw Self.ParseError.malformed(attr) }
    let symbolName: Substring = s1[0]

    let s2: [Substring] = s1[1].split(separator: "=", maxSplits: 1)
    let attrName: Substring = s2[0]
    let args: [Substring]
    if s2.count == 2 {
      args = s2[1].split(separator: ",")
    } else {
      args = []
    }

    return Attribute(
      symbolName: symbolName,
      attributeName: attrName,
      arguments: args,
      originalArgument: attr
    )
  }

  private init(
    symbolName: Substring,
    attributeName: Substring,
    arguments: [Substring],
    originalArgument: String
  ) {
    self.symbolName = symbolName
    self.attributeName = attributeName
    self.arguments = arguments
    self.origin = OctoOrigin(arg: originalArgument)
  }

  public init?(argument: String) {
    do {
      self = try Self.parse(argument)
    } catch let error {
      print("\(error)", to: .stderr)
      return nil
    }
  }

  var asOctoAttribute: OctoAttribute {
    OctoAttribute(
      name: "octo:\(self.attributeName)",
      type: .annotate,
      params: arguments.map { arg in
        if let i = Int(arg) {
          return OctoAttribute.Parameter.int(i)
        } else if let d = Double(arg) {
          return OctoAttribute.Parameter.double(d)
        } else {
          return OctoAttribute.Parameter.string(arg)
        }
      },
      origin: self.origin
    )
  }
}

extension Attribute: Decodable {
  enum CodingKeys: String, CodingKey {
     case symbolName = "symbol"
     case attributeName = "attribute"
     case arguments
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let symbol = try container.decode(String.self, forKey: .symbolName)
    let attribute = try container.decode(String.self, forKey: .attributeName)
    let arguments: [String] = try container.decodeIfPresent([String].self, forKey: .arguments) ?? []
    let argumentsSub: [Substring] = arguments.map { $0[$0.startIndex..<$0.endIndex] }

    self = Attribute(
      symbolName: symbol[symbol.startIndex..<symbol.endIndex],
      attributeName: attribute[attribute.startIndex..<attribute.endIndex],
      arguments: argumentsSub,
      originalArgument: "TODO: line number in TOML file"
    )
  }
}
