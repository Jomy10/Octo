import Foundation

public protocol OctoObject {
  var id: UUID { get }
  var origin: OctoOrigin { get }
}

//public enum OctoObjectType {
//  case userType
//  case globalVariable
//  case function
//}
