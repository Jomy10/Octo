import Clang

struct OctoOrigin {
  private let inner: OriginData

  init(c: CXSourceLocation) {
    self.inner = .c(c)
  }

  enum OriginData {
    case c(CXSourceLocation)
  }

  var file: String {
    switch (self.inner) {
      case .c(let loc): return loc.expansionLocation.file.fileName
    }
  }

  var line: UInt {
    switch (self.inner) {
      case .c(let loc): return UInt(loc.expansionLocation.line)
    }
  }

  var column: UInt {
    switch (self.inner) {
      case .c(let loc): return UInt(loc.expansionLocation.column)
    }
  }
}

extension OctoOrigin: CustomStringConvertible {
  var description: String {
    return "\(file)@\(line):\(column)"
  }
}

extension OctoOrigin: Equatable {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    switch (lhs.inner) {
      case .c(let lloc):
        guard case .c(let rloc) = rhs.inner else {
          return false
        }
        return lloc == rloc
    }
  }
}
