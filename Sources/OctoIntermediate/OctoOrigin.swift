import Foundation

public enum OctoOrigin {
  case file(file: URL, line: UInt, column: UInt)
  case other(String)
  case none
}
