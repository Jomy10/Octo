import Foundation

protocol OctoObject {
  var id: UUID { get }
  var origin: OctoOrigin { get }
}

enum OctoObjectType {
  case userType
  case globalVariable
  case function
}
