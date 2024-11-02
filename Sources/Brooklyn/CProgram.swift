import Clang

struct CProgram {
  var userTypes: [String:CUserType]
  var typedefs: [String:CType]
  var globalVariables: [String:CVariable]
  var functions: [String:CFunction]

  enum Error: Swift.Error {
    case userTypeExists(name: String)
    case userTypeDoesntExist(name: String)
    case typedefExists(name: String)
    case globalVariableExists(name: String)
    case enumConstantExists(name: String)
    case userTypeWrongType(name: String, expected: String)
    case functionExists(name: String)
  }

  public init() {
    self.userTypes = [:]
    self.typedefs = [:]
    self.globalVariables = [:]
    self.functions = [:]
  }

  public mutating func addUserType(_ type: CUserType) /*throws(Self.Error)*/ throws {
    let name: String = type.userTypeName

    if self.userTypes[name] != nil {
      throw Self.Error.userTypeExists(name: name)
    }

    self.userTypes[name] = type
  }

  public func getUserType(_ name: String) -> CUserType? {
    return self.userTypes[name]
  }

  public mutating func addField(to structName: String, _ field: CField) /*throws(Self.Error)*/ throws {
    if self.userTypes[structName] == nil {
      throw Self.Error.userTypeDoesntExist(name: structName)
    }

    switch (self.userTypes[structName]) {
      case .union(var u):
        u.addField(field)
        self.userTypes[structName] = .union(u)
      case .struct(var s):
        s.addField(field)
        self.userTypes[structName] = .struct(s)
      default:
        throw Self.Error.userTypeWrongType(name: structName, expected: "struct or union")
    }
  }

  public mutating func addEnumConstant(to enumName: String, _ constant: CEnumConstant) /*throws(Self.Error)*/ throws {
    if self.userTypes[enumName] == nil {
      throw Self.Error.userTypeDoesntExist(name: enumName)
    }

    guard case .enum(var e) = self.userTypes[enumName] else {
      throw Self.Error.userTypeWrongType(name: enumName, expected: "enum")
    }
    try e.addEnumConstant(constant)
    self.userTypes[enumName] = .enum(e)
  }

  public mutating func addTypedef(_ typedefName: String, _ referredToType: CType) /*throws(Self.Error)*/ throws {
    if self.typedefs[typedefName] != nil {
      throw Self.Error.typedefExists(name: typedefName)
    }

    self.typedefs[typedefName] = referredToType
  }

  public mutating func addGlobalVariable(_ variable: CVariable) /*throws(Self.Error)*/ throws {
    if self.globalVariables[variable.name] != nil {
      throw Self.Error.globalVariableExists(name: variable.name)
    }

    self.globalVariables[variable.name] = variable
  }

  public mutating func addFunction(_ fn: CFunction) throws {
    if self.functions[fn.name] != nil {
      throw Self.Error.functionExists(name: fn.name)
    }

    self.functions[fn.name] = fn
  }
}

extension CProgram: CustomStringConvertible {
  var description: String {
    """
    Program
    =======
    userTypes:
    \(self.userTypes.map { k, v in "  \(k): \(v)" }.joined(separator: "\n"))
    typedefs:
    \(self.typedefs.map { k, v in "  \(k): \(v)" }.joined(separator: "\n"))
    globalVariables:
    \(self.globalVariables.map { k, v in "  \(k): \(v)" }.joined(separator: "\n"))
    functions:
    \(self.functions.map { k, v in "  \(k): \(v)" }.joined(separator: "\n"))
    """
  }
}

enum CUserType {
  case `struct`(CRecord)
  case union(CRecord)
  case `enum`(CEnum)
}

extension CUserType {
  var userTypeName: String {
    switch (self) {
      case .struct(let s):
        return s.name
      case .union(let u):
        return u.name
      case .enum(let e):
        return e.name
    }
  }
}

struct CRecord {
  let name: String
  var fields: [CField]
  let origin: CXSourceLocation

  init(name: String, origin: CXSourceLocation) {
    self.name = name
    self.fields = []
    self.origin = origin
  }

  mutating func addField(_ field: CField) {
    self.fields.append(field)
  }
}

struct CField {
  let type: CType
  let name: String
}

struct CEnum {
  let type: CType
  let name: String
  var constants: [String:CEnumConstant]
  let origin: CXSourceLocation
  var isSigned: Bool {
    return self.type.kind == .Int
  }

  init(type: CType, name: String, origin: CXSourceLocation) {
    self.type = type
    self.name = name
    self.constants = [:]
    self.origin = origin
  }

  mutating func addEnumConstant(_ ecase: CEnumConstant) throws {
    if self.constants[ecase.name] != nil {
      throw CProgram.Error.enumConstantExists(name: ecase.name)
    }

    self.constants[ecase.name] = ecase
  }
}

struct CEnumConstant {
  let name: String
  let value: Self.Value

  enum Value {
    case signed(Int64)
    case unsigned(UInt64)
  }

  init(name: String, signedValue: Int64) {
    self.name = name
    self.value = .signed(signedValue)
  }

  init(name: String, unsignedValue: UInt64) {
    self.name = name
    self.value = .unsigned(unsignedValue)
  }

  init(name: String, value: Self.Value) {
    self.name = name
    self.value = value
  }
}

struct CVariable {
  let type: CType
  let name: String
  let external: Bool
  let origin: CXSourceLocation
}

struct CFunction {
  let type: CType
  let name: String
}
