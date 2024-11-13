import Octo
import OctoIO
import ArgumentParser

struct Attribute: Equatable, Hashable, ExpressibleByArgument {
  let symbolName: Substring
  let attributeName: Substring
  let arguments: [Substring]
  let originalArgument: String

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
    self.originalArgument = originalArgument
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
      origin: OctoOrigin(arg: originalArgument)
    )
  }
}
