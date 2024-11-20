import Foundation
import OctoIO

public struct OctoGlobalVariable: OctoObject {
  public let id = UUID()

  let type: OctoType
  let name: String
  let external: Bool
  public let origin: OctoOrigin
}
