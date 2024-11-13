import Foundation

public struct OctoTypedef: OctoObject {
  public let id = UUID()

  let name: String
  let refersTo: OctoType
  public let origin: OctoOrigin

  var bindingName: String {
    self.name
  }
}
