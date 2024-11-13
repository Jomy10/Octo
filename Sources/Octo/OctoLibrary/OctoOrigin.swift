import Clang

public struct OctoOrigin {
  private let inner: OriginData

  init(c: CXSourceLocation) {
    self.inner = .c(c)
  }

  public init(arg: String) {
    self.inner = .arg(arg)
  }

  enum OriginData: Equatable {
    case c(CXSourceLocation)
    case arg(String)
  }

  var file: String {
    switch (self.inner) {
      case .c(let loc): return loc.expansionLocation.file.fileName
      case .arg: return "argument"
    }
  }

  var line: UInt {
    switch (self.inner) {
      case .c(let loc): return UInt(loc.expansionLocation.line)
      case .arg: return 0
    }
  }

  var column: UInt {
    switch (self.inner) {
      case .c(let loc): return UInt(loc.expansionLocation.column)
      case .arg: return 0
    }
  }
}

extension OctoOrigin: CustomStringConvertible {
  public var description: String {
    if case .arg(let arg) = self.inner {
      return "argument: \(arg)"
    }
    return "\(file)@\(line):\(column)"
  }
}

extension OctoOrigin: Equatable {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.inner == rhs.inner
  }
}
