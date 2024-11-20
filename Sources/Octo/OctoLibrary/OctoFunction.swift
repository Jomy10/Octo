import Foundation
import OctoIO

public struct OctoFunction: OctoObject, OctoRenamable {
  public let id = UUID()

  var type: OctoType
  let name: String
  /// Name of 'octo:rename' attribute
  var customName: String? = nil
  public let origin: OctoOrigin
  var functionType: OctoFunctionType = .function
  var params: [UUID] = []
  var visible = true
  var attachedTo: UUID? = nil

  var isAttached: Bool {
    attachedTo != nil
  }

  var canReturnNull: Bool {
    get {
      guard case .Function(callingConv: _, args: _, result: let result) = self.type.kind else {
        octoLogger.fatal("unreachable")
      }
      return result.nullable
    }
    set {
      guard case .Function(callingConv: let callingConv, args: let args, result: var result) = self.type.kind else {
        octoLogger.fatal("unreachable")
      }
      result.nullable = newValue
      self.type = self.type.copy(mutatingKind: .Function(callingConv: callingConv, args: args, result: result))
    }
  }

  public var bindingName: String {
    self.customName ?? self.name
  }

  var returnType: OctoType {
    guard case .Function(callingConv: _, args: _, result: let resultType) = self.type.kind else {
      octoLogger.fatal("unreachable")
    }

    return resultType
  }

  func selfParameter(in lib: OctoLibrary) -> Int? {
    if self.functionType == .function || self.functionType == .`init` || self.functionType == .`staticMethod` {
      return nil
    }

    guard let attachedToId = self.attachedTo else {
      octoLogger.fatal("bug")
    }

    guard case .Function(callingConv: _, args: let args, result: _) = self.type.kind else {
      octoLogger.fatal("unreachable")
    }

    let attachedToType = lib.getUserType(id: attachedToId)!

    let res: Int? = args.enumerated().first(where: { (i: Int, argType: OctoType) -> Bool in
      let typeName: String
      let typeLid: OctoLibrary.LangId?
      switch (argType.kind) {
        case .UserDefined(name: let userTypeName, id: let id):
          typeName = userTypeName
          typeLid = id
        case .Pointer(to: let pointeeTypeName):
          guard case .UserDefined(name: let userTypeName, id: let id) = pointeeTypeName.kind else {
            return false
          }
          typeName = userTypeName
          typeLid = id
        default: return false
      }

      let userTypeId = (typeLid == nil ? nil : lib.getUserType(lid: typeLid!)) ?? lib.getUserType(name: typeName)!
      let userType = lib.getUserType(id: userTypeId)!
      return userType == attachedToType
    }).map { (i, argType) in i }

    guard let argNum = res else {
      let attachedToTypeName: String
      switch (attachedToType.inner) {
        case .record(let record): attachedToTypeName = record.name
        case .`enum`(let e): attachedToTypeName = e.name
      }
      octoLogger.warning("Attached function of type \(self.functionType) does not have a `self` parameter of type '\(attachedToTypeName)'", origin: origin)
      return nil
    }

    //let selfType = lib.getUserType(id: selfParamId)!
    return argNum
  }

  var containsUserType: Bool {
    get {
      return self.type.containsUserType
    }
  }

  mutating func addParam(_ id: UUID) {
    self.params.append(id)
  }

  mutating func markAttached(type: OctoFunctionType, toType attachedToId: UUID) {
    if self.functionType != .function {
      octoLogger.warning("Function marked as attached multiple times", origin: self.origin)
    }
    self.functionType = type
    self.attachedTo = attachedToId
  }

  public mutating func rename(to newName: String) {
    self.customName = newName
  }
}

public struct OctoParam: OctoObject {
  public let id = UUID()

  var type: OctoType
  let name: String?
  public let origin: OctoOrigin
  var visible = true

  var bindingName: String? {
    self.name
  }

  var nullable: Bool {
    get {
      self.type.nullable
    }
    set {
      self.type.nullable = newValue
    }
  }
}

public enum OctoFunctionType {
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
