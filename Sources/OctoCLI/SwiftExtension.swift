import Foundation
import ArgumentParser

extension URL: ExpressibleByArgument {
  public init?(argument: String) {
    self = URL(filePath: argument)
  }
}

extension Array {
  func get(_ idx: Self.Index) -> Self.Element? {
    if idx < self.count {
      return self[idx]
    } else {
      return nil
    }
  }
}
