import Foundation

struct OctoGlobalVariable: OctoObject {
  let id = UUID()

  let type: OctoType
  let name: String
  let external: Bool
  let origin: OctoOrigin
}
