import Foundation

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

//extension OctoObject & OctoRenamable {
//  var isRenamable: Bool { true }
//}

public protocol OctoRenamable {
  mutating func rename(to: String)
  var bindingName: String { get }
}

//public enum OctoObjectType {
//  case userType
//  case globalVariable
//  case function
//}
