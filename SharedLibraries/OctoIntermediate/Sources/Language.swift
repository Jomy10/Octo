public enum Language {
  case c
  case cxx
  case swift
  case rust
  case ruby
  case other(String)
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
