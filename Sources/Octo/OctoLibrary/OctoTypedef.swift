import Foundation

public struct OctoTypedef: OctoObject {
  public let id = UUID()

  let name: String
  var refersTo: OctoType
  public let origin: OctoOrigin

  var bindingName: String {
    self.name
  }
}
