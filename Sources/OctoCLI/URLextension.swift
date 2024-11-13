import Foundation
import ArgumentParser

extension URL: ExpressibleByArgument {
  public init?(argument: String) {
    self = URL(fileURLWithPath: argument)
  }
}
