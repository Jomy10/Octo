import Foundation

public enum OctoOrigin {
  case file(file: URL, line: UInt, column: UInt)
  case other(String)
  case argument
  case none
}

extension OctoOrigin: CustomStringConvertible {
  public var description: String {
    switch (self) {
      case .file(file: let file, line: let line, column: let column):
        return "\(file.path):\(line):\(column)"
      case .other(let msg): return msg
      case .argument: return "argument"
      case .none: return ""
    }
  }
}
