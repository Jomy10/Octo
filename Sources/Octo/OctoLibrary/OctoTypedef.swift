import Foundation

struct OctoTypedef: OctoObject {
  let id = UUID()

  let name: String
  let refersTo: OctoType
  let origin: OctoOrigin
    
  var bindingName: String {
    self.name
  }
}
