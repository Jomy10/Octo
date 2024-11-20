import Foundation
import Logging
import OctoIO

public protocol OctoObject {
  var id: UUID { get }
  var origin: OctoOrigin { get }
  var isRenamable: Bool { get }
}

extension OctoObject {
  public var isRenamable: Bool {
    if Self.self is OctoRenamable.Type {
      return true
    } else {
      return false
    }
  }
}

public protocol OctoRenamable {
  mutating func rename(to: String)
  var bindingName: String { get }
}

protocol OctoSubObject {
  var origin: OctoOrigin { get }
}
