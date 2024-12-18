public enum Language: Equatable, Hashable, Sendable {
  case c
  case cxx
  case swift
  case rust
  case ruby
  case other(String)

  public init(fromString stringValue: String) {
    switch (stringValue.lowercased()) {
      case "c": self = .c
      case "cxx": fallthrough
      case "c++": fallthrough
      case "cpp": self = .cxx
      case "swift": self = .swift
      case "rust": self = .rust
      case "rb": fallthrough
      case "ruby": self = .ruby
      default: self = .other(stringValue)
    }
  }
}

extension Language: CustomStringConvertible {
  public var description: String {
    switch (self) {
      case .c: return "C"
      case .cxx: return "C++"
      case .swift: return "Swift"
      case .rust: return "Rust"
      case .ruby: return "Ruby"
      case .other(let name): return name
    }
  }
}
