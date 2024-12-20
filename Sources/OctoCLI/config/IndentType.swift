import ArgumentParser

enum IndentType: ExpressibleByArgument, Decodable {
  case tabs
  case spaces

  init?(argument: String) {
    switch (argument) {
      case "tabs": self = .tabs
      case "spaces": self = .spaces
      default: return nil
    }
  }

  var stringValue: String {
    switch (self) {
      case .tabs: return "\t"
      case .spaces: return " "
    }
  }
}
