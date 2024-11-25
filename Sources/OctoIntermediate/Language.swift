public enum Language {
  case c
  case cxx
  case swift
  case rust
  case ruby
}

extension Language: CustomStringConvertible {
  public var description: String {
    switch (self) {
      case .c: return "C"
      case .cxx: return "C++"
      case .swift: return "Swift"
      case .rust: return "Rust"
      case .ruby: return "Ruby"
    }
  }
}
