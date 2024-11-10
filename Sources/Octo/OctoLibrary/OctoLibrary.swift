import Foundation
import Clang

struct OctoLibrary {
  var name: String

  /// Look up an Octo object based on its cursor
  var cursorMap: [LangId:UUID] = [:]
  /// Look up an Octo object based on its name
  var nameLookup: [String:UUID] = [:]
  /// Retrieve the type of an octo object
  var objectTypeLookup: [UUID:OctoObject.Type] = [:]

  var destroy: () -> Void = {}

  enum LangId: Hashable {
    case c(CXCursor)
  }

  var userTypes: [UUID:OctoUserType] = [:]
  var recordFields: [UUID:OctoField] = [:]
  var enumCases: [UUID:OctoEnumCase] = [:]
  var globalVariables: [UUID:OctoGlobalVariable] = [:]
  var functions: [UUID:OctoFunction] = [:]
  var functionParameters: [UUID:OctoParam] = [:]
  var typedefs: [UUID:OctoTypedef] = [:]
  var attributes: [UUID:OctoAttribute] = [:]

  // Add objects //
  private mutating func addObject<Obj: OctoObject>(_ obj: Obj, id langId: LangId, name: String?) {
    self.cursorMap[langId] = obj.id
    if let n = name {
      self.nameLookup[n] = obj.id
    }
    self.objectTypeLookup[obj.id] = Obj.self
    if obj is OctoUserType {
      self.userTypes[obj.id] = (obj as! OctoUserType)
    } else if obj is OctoGlobalVariable {
      self.globalVariables[obj.id] = (obj as! OctoGlobalVariable)
    } else if obj is OctoFunction {
      self.functions[obj.id] = (obj as! OctoFunction)
    } else if obj is OctoTypedef {
      self.typedefs[obj.id] = (obj as! OctoTypedef)
    } else if obj is OctoAttribute {
      self.attributes[obj.id] = (obj as! OctoAttribute)
    } else if obj is OctoParam {
      self.functionParameters[obj.id] = (obj as! OctoParam)
    } else if obj is OctoField {
      self.recordFields[obj.id] = (obj as! OctoField)
    } else if obj is OctoEnumCase {
      self.enumCases[obj.id] = (obj as! OctoEnumCase)
    } else {
      fatalError("Unhandled OctoObject type \(Obj.self)")
    }
  }

  mutating func addUserType<ID: Into>(enum v: OctoEnum, id: ID) where ID.T == LangId {
    self.addObject(OctoUserType(inner: .enum(v)), id: id.into(), name: v.name)
  }

  mutating func addUserType<ID: Into>(record: OctoRecord, id: ID) where ID.T == LangId {
    self.addObject(OctoUserType(inner: .record(record)), id: id.into(), name: record.name)
  }

  mutating func addField<ID: Into>(to recordId: UUID, _ field: OctoField, id: ID) where ID.T == LangId {
    self.addObject(field, id: id.into(), name: field.name)
    if !(self.mutateRecord(id: recordId) { (record: inout OctoRecord) in
      record.addField(field.id)
    }) {
      fatalError("Could not mutate record \(recordId)")
    }
  }

  mutating func addEnumCase<ID: Into>(to enumId: UUID, _ enumCase: OctoEnumCase, id: ID) where ID.T == LangId {
    self.addObject(enumCase, id: id.into(), name: enumCase.name)
    if !(self.mutateEnum(id: enumId) { (v: inout OctoEnum) in
      v.addCase(enumCase.id)
    }) {
      fatalError("Could not mutate enum \(enumId)")
    }
  }

  mutating func addGlobalVariable<ID: Into>(_ variable: OctoGlobalVariable, id: ID) where ID.T == LangId {
    self.addObject(variable, id: id.into(), name: variable.name)
  }

  mutating func addTypedef<ID: Into>(_ typedef: OctoTypedef, id: ID) where ID.T == LangId {
    self.addObject(typedef, id: id.into(), name: typedef.name)
  }

  mutating func addFunction<ID: Into>(_ function: OctoFunction, id: ID) where ID.T == LangId {
    self.addObject(function, id: id.into(), name: function.name)
  }

  mutating func addParam<ID: Into>(to functionId: UUID, _ param: OctoParam, id: ID) where ID.T == LangId {
    self.addObject(param, id: id.into(), name: param.name)
    if !(self.mutateFunction(id: functionId) { (fun: inout OctoFunction) in
      fun.addParam(param.id)
    }) {
      fatalError("Could not mutate \(functionId)")
    }
  }

  mutating func addAttribute<ID: Into>(to parentId: UUID, _ attr: OctoAttribute, id: ID) where ID.T == LangId {
    self.addObject(attr, id: id.into(), name: nil)
    let parentObjectType = self.objectTypeLookup[parentId]
    if parentObjectType == OctoFunction.self {
      switch (attr.octoData) {
      case .attach(to: let userTypeName, type: let functionType):
        guard let userTypeId = self.getUserType(name: userTypeName) else {
          fatalError("[\(attr.origin)] ERROR: user type \(userTypeName) does not exist")
        }

        // Attach the function
        switch (self.userTypes[userTypeId]!.inner) {
        case .record(_):
          if !(self.mutateRecord(id: userTypeId) { (record: inout OctoRecord) in
            record.attachFunction(parentId, type: functionType)
          }) { fatalError("Couldn't mutate \(userTypeId)") }
        case .`enum`(_):
          if !(self.mutateEnum(id: userTypeId) { (v: inout OctoEnum) in
            v.attachFunction(parentId, type: functionType)
          }) { fatalError("Couldn't mutate \(userTypeId)") }
        }
        print("attached to: \(self.getUserType(id: userTypeId)!)")

        // Mark the function as attached
        if !(self.mutateFunction(id: parentId) { (function: inout OctoFunction) in
          function.markAttached(type: functionType, toType: userTypeId)
        }) { fatalError("Couldn't mutate \(parentId)") }

        print("the function: \(self.getFunction(id: parentId)!)")
        // End attach function
      case .rename(to: let newName):
        if !(self.mutateFunction(id: parentId) { (function: inout OctoFunction) in
          function.rename(to: newName)
        }) { fatalError("Couldn't mutate \(parentId)") }
        // End Rename
      case .hidden:
        if !(self.mutateFunction(id: parentId) { function in
          function.visible = false
        }) { fatalError("Couldn't mutate \(parentId)") }
      case nil:
        // Not an octo attribute
        switch (attr.name) {
          case "returns_nonnull":
            if !(self.mutateFunction(id: parentId) { function in
              function.canReturnNull = false
            }) { fatalError("Couldn't mutate \(parentId)") }
          default:
            print("[WARNING] Attribute \(attr.name) ignored")
            break // ignore
        }
      default:
        fatalError("[\(attr.origin)] ERROR: Attribute type \(String(describing: attr.octoData)) cannot be applied to function (for attribute \(attr))")
      }
    } else if parentObjectType == OctoParam.self {
      switch (attr.octoData) {
      //case .hidden:
      //  if !(self.mutateParameter(id: parentId) { param in
      //    param.visible = false
      //  }) { fatalError("Couldn't mutate \(parentId)") }
      case nil:
        // non-octo attribute
        switch (attr.name) {
        case "nonnull":
          if !(self.mutateParameter(id: parentId) { param in
            param.nullable = false
          }) { fatalError("Couldn't mutate \(parentId)") }
        case "nullable":
          if !(self.mutateParameter(id: parentId) { param in
            param.nullable = true
          }) { fatalError("Couldn't mutate \(parentId)") }
        default:
          print("[WARNING] Attribute \(attr.name) ignored")
          break // ignore
        }
      default:
        fatalError("[\(attr.origin)] ERROR: Attribute type \(String(describing: attr.octoData)) cannot be applied to function parameter (for attribute \(attr))")
      }
    } else if parentObjectType == OctoField.self {
      switch (attr.octoData) {
      case .hidden:
        if !(self.mutateField(id: parentId) { field in
          field.visible = false
        }) { fatalError("Couldn't mutate \(parentId)") }
      case nil:
        // non-octo attribute
        switch (attr.name) {
        case "nonnull":
          if !(self.mutateField(id: parentId) { field in
            field.nullable = false
          }) { fatalError("Couldn't mutate \(parentId)") }
        case "nullable":
          if !(self.mutateField(id: parentId) { field in
            field.nullable = true
          }) { fatalError("Couldn't mutate \(parentId)") }
        default:
          print("[WARNING] Attribute \(attr.name) ignored")
          break // ignore
        }
        default:
          fatalError("[\(attr.origin)] Attribute '\(attr.name)' cannot be applied to record field")
      }
    } else { // end function
      fatalError("Unhandled OctoObject type in `addAttribute`: \(String(describing: parentObjectType))")
    }
  }

  // Getters
  func getObject<ID: Into>(lid: ID) -> UUID? where ID.T == LangId {
    return self.cursorMap[lid.into()]
  }

  private func getUserTypeId(possibleId objid: UUID) -> UUID? {
    let type = self.objectTypeLookup[objid]
    if type == OctoUserType.self {
      return objid
    } else if type == OctoTypedef.self {
      let typedef = self.typedefs[objid]!
      if case .UserDefined(name: let name) = typedef.refersTo.kind {
        return self.getUserType(name: String(name))
      } else {
        return nil
      }
    } else {
      // Object is not a user type
      return nil
    }
  }

  func getUserType(name: String) -> UUID? {
    guard let objid = self.nameLookup[name] else {
      // Type doesn't exist
      return nil
    }

    return self.getUserTypeId(possibleId: objid)
  }

  func getUserType<ID: Into>(lid: ID) -> UUID? where ID.T == LangId {
    guard let objid = self.cursorMap[lid.into()] else {
      // Type doesn't exist
      return nil
    }

    return self.getUserTypeId(possibleId: objid)
  }

  func getUserType(id: UUID) -> OctoUserType? {
    return self.userTypes[id]
  }

  func isUserType(name: String) -> Bool {
    return self.getUserType(name: name) != nil
  }

  func getTypedef(name: String) -> UUID? {
    guard let objid = self.nameLookup[name] else {
      // Object doesn't exist
      return nil
    }

    return self.isTypedef(id: objid) ? objid : nil
  }

  func getTypedef<ID: Into>(lid: ID) -> UUID? where ID.T == LangId {
    guard let objid = self.cursorMap[lid.into()] else {
      return nil
    }

    return self.isTypedef(id: objid) ? objid : nil
  }

  func getTypedef(id: UUID) -> OctoTypedef? {
    self.typedefs[id]
  }

  func isTypedef(id: UUID) -> Bool {
    if OctoTypedef.self == self.objectTypeLookup[id] {
      return true
    } else {
      // Object is of the wrong type
      return false
    }
  }

  func getFunction<ID: Into>(lid: ID) -> UUID? where ID.T == LangId {
    guard let objid = self.cursorMap[lid.into()] else {
      return nil
    }

    return self.isFunction(id: objid) ? objid : nil
  }

  func getFunction(id: UUID) -> OctoFunction? {
    self.functions[id]
  }

  func isFunction(id: UUID) -> Bool {
    return self.functions[id] != nil
  }

  func getField(id: UUID) -> OctoField? {
    self.recordFields[id]
  }

  func getParameter(id: UUID) -> OctoParam? {
    self.functionParameters[id]
  }

  func getEnumCase(id: UUID) -> OctoEnumCase? {
    self.enumCases[id]
  }

  // Setters
  mutating func mutateRecord(id: UUID, _ mutate: (inout OctoRecord) throws -> Void) rethrows -> Bool {
    if case .record(var record) = self.userTypes[id]?.inner {
      try mutate(&record)
      self.userTypes[id]!.inner = .record(record)
      return true
    } else {
      return false
    }
  }

  mutating func mutateEnum(id: UUID, _ mutate: (inout OctoEnum) throws -> Void) rethrows -> Bool {
    if case .`enum`(var e) = self.userTypes[id]?.inner {
      try mutate(&e)
      self.userTypes[id]!.inner = .`enum`(e)
      return true
    } else {
      return false
    }
  }

  mutating func mutateFunction(id: UUID, _ mutate: (inout OctoFunction) throws -> Void) rethrows -> Bool {
    if self.functions[id] == nil {
      return false
    }
    try mutate(&self.functions[id]!)
    return true
  }

  mutating func mutateParameter(id: UUID, _ mutate: (inout OctoParam) throws -> Void) rethrows -> Bool {
    if self.functionParameters[id] == nil {
      return false
    }
    try mutate(&self.functionParameters[id]!)
    return true
  }

  mutating func mutateField(id: UUID, _ mutate: (inout OctoField) throws -> Void) rethrows -> Bool {
    if self.recordFields[id] == nil {
      return false
    }
    try mutate(&self.recordFields[id]!)
    return true
  }
}

extension OctoLibrary.LangId: Into {
  typealias T = OctoLibrary.LangId
  func into() -> T {
    self
  }
}

extension OctoLibrary: CustomStringConvertible {
  var description: String {
    """
    Library: \(self.name)
    =========\(String(repeating: "=", count: self.name.count))
    userTypes:
    \(self.userTypes.map { (k, v) in "  \(k):\(v)" }.joined(separator: "\n"))
    fields:
    \(self.recordFields.map { (k, v) in "  \(k):\(v)" }.joined(separator: "\n"))
    enumCases:
    \(self.enumCases.map { (k, v) in "  \(k):\(v)" }.joined(separator: "\n"))
    globalVariables:
    \(self.globalVariables.map { (k, v) in "  \(k):\(v)" }.joined(separator: "\n"))
    functions:
    \(self.functions.map { (k, v) in "  \(k):\(v)" }.joined(separator: "\n"))
    parameters:
    \(self.functionParameters.map { (k, v) in "  \(k):\(v)" }.joined(separator: "\n"))
    typedefs:
    \(self.typedefs.map { (k, v) in "  \(k):\(v)" }.joined(separator: "\n"))
    attributes:
    \(self.attributes.map { (k, v) in "  \(k):\(v)" }.joined(separator: "\n"))
    """
  }
}
