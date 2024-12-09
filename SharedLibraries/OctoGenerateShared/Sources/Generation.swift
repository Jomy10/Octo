import Foundation

public protocol GeneratedCode {
  func write(to url: URL) throws
}

public func indentCode(indent: String, @StringBuilder _ str: () throws -> String) rethrows -> String {
  try str().split(whereSeparator: \.isNewline)
    .map { "\(indent)\($0)" }
    .joined(separator: "\n")
}

public func codeBuilder(@StringBuilder _ str: () throws -> String) rethrows -> String {
  try str()
}
