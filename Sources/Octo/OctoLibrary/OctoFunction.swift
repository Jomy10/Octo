import Foundation
import OctoIO

struct OctoFunction: OctoObject {
  let id = UUID()

  var type: OctoType
  let name: String
  /// Name of 'octo:rename' attribute
  var customName: String? = nil
  let origin: OctoOrigin
  var functionType: OctoFunctionType = .function
  var params: [UUID] = []
  var visible = true

  var canReturnNull: Bool {
    get {
      guard case .Function(callingConv: let _, args: let _, result: let result) = self.type.kind else {
        fatalError("unreachable")
      }
      return result.nullable
    }
    set {
      guard case .Function(callingConv: let callingConv, args: let args, result: var result) = self.type.kind else {
        fatalError("unreachable")
      }
      result.nullable = newValue
      self.type = self.type.copy(mutatingKind: .Function(callingConv: callingConv, args: args, result: result))
    }
  }

  var bindingName: String {
    self.customName ?? self.name
  }

  mutating func addParam(_ id: UUID) {
    self.params.append(id)
  }

  mutating func markAttached(type: OctoFunctionType) {
    if self.functionType != .function {
      print("[WARNING] Function marked as attached multiple times", to: .stderr)
    }
    self.functionType = type
  }

  mutating func rename(to newName: String) {
    self.customName = newName
  }
}

struct OctoParam: OctoObject {
  let id = UUID()

  var type: OctoType
  let name: String?
  let origin: OctoOrigin
  var visible = true

  var nullable: Bool {
    get {
      self.type.nullable
    }
    set {
      self.type.nullable = newValue
    }
  }
}

enum OctoFunctionType {
  case `init`
  case `deinit`
  case method
  case staticMethod
  case function

  init?(_ s: some StringProtocol) {
    switch (s) {
      case "init": self = .`init`
      case "deinit": self = .`deinit`
      case "method": self = .method
      case "staticMethod": self = .staticMethod
      default: return nil
    }
  }
}
