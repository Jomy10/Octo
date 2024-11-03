import Clang

enum Language {
  case ruby
}

struct CProgram {
  var userTypes: [String:CUserType]
  var typedefs: [String:CTypedef]
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
    case functionDoesntExist(name: String)
    case parameterExists(name: String, functionName: String)
    case parameterDoesntExist(name: String, functionName: String)
  }

  public init() {
    self.userTypes = [:]
    self.typedefs = [:]
    self.globalVariables = [:]
    self.functions = [:]
  }

  public func convert(
    language: Language,
    headerIncludes: ((String) throws -> Bool)? = nil,
    options: ConversionOptions
  ) throws -> String {
    switch (language) {
      case .ruby: return try self.convertRuby(headerIncludes, options: options)
    }
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

  public mutating func addTypedef(_ typedef: CTypedef) /*throws(Self.Error)*/ throws {
    if self.typedefs[typedef.name] != nil {
      throw Self.Error.typedefExists(name: typedef.name)
    }

    self.typedefs[typedef.name] = typedef
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

  public mutating func addParam(to functionName: String, _ param: CParam) throws {
    if self.functions[functionName] == nil {
      throw Self.Error.functionDoesntExist(name: functionName)
    }

    try self.functions[functionName]!.addParam(param)
  }

  public mutating func addAttribute(toFunction functionName: String, _ attr: CAttribute) throws {
    if self.functions[functionName] == nil {
      throw Self.Error.functionDoesntExist(name: functionName)
    }

    self.functions[functionName]!.addAttribute(attr)
  }

  public mutating func addAttribute(toParameter parameterCursor: CXCursor, belongingToFunction functionName: String, _ attr: CAttribute) throws {
    if self.functions[functionName] == nil {
      throw Self.Error.functionDoesntExist(name: functionName)
    }

    try self.functions[functionName]!.addAttribute(toParameter: parameterCursor, attr)
  }

  public mutating func addAttribute(toRecord recordName: String, _ attr: CAttribute) throws {
    if self.userTypes[recordName] == nil {
      throw Self.Error.userTypeDoesntExist(name: recordName)
    }

    self.userTypes[recordName]!.addAttribute(attr)
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

  var origin: CXSourceLocation {
    switch (self) {
      case .struct(let record): return record.origin
      case .union(let record): return record.origin
      case .enum(let cenum): return cenum.origin
    }
  }

  mutating func addAttribute(_ attr: CAttribute) {
    switch (self) {
      case .struct(var record):
        record.addAttribute(attr)
        self = .struct(record)
      case .union(var record):
        record.addAttribute(attr)
        self = .union(record)
      case .enum(var cenum):
        cenum.addAttribute(attr)
        self = .enum(cenum)
    }
  }
}

struct CRecord {
  let name: String
  var fields: [CField]
  let origin: CXSourceLocation
  var attributes: [CAttribute] = []

  init(name: String, origin: CXSourceLocation) {
    self.name = name
    self.fields = []
    self.origin = origin
  }

  mutating func addField(_ field: CField) {
    self.fields.append(field)
  }

  mutating func addAttribute(_ attr: CAttribute) {
    self.attributes.append(attr)
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
  var attributes: [CAttribute] = []

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

  mutating func addAttribute(_ attr: CAttribute) {
    self.attributes.append(attr)
  }
}

struct CEnumConstant {
  let name: String
  let value: Self.Value

  enum Value: CustomStringConvertible {
    case signed(Int64)
    case unsigned(UInt64)

    var description: String {
      switch (self) {
        case .signed(let value): return String(value)
        case .unsigned(let value): return String(value)
      }
    }
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
  let origin: CXSourceLocation
  var parameters: [CParam] = []
  var parametersMap: [CXCursor:Int] = [:]
  var attributes: [CAttribute] = []

  var returnType: CType {
    switch (self.type.kind) {
      case .FunctionProto(callingConv: _, args: _, result: let result): return result
      case .FunctionNoProto(callingConv: _, args: _, result: let result): return result
      default: fatalError("Invalid function type \(self.type)")
    }
  }

  mutating func addParam(_ param: CParam) throws {
    if self.parametersMap[param.cursor] != nil {
      throw CProgram.Error.parameterExists(name: param.name ?? "unnamed", functionName: self.name)
    }

    let id = self.parameters.count
    self.parameters.append(param)
    self.parametersMap[param.cursor] = id
  }

  mutating func addAttribute(_ attr: CAttribute) {
    self.attributes.append(attr)
  }

  mutating func addAttribute(toParameter parameterCursor: CXCursor, _ attr: CAttribute) throws {
    if self.parametersMap[parameterCursor] == nil {
      throw CProgram.Error.parameterDoesntExist(name: parameterCursor.spelling!, functionName: self.name)
    }

    self.parameters[self.parametersMap[parameterCursor]!].addAttribute(attr)
  }
}

struct CParam {
  let type: CType
  let name: String?
  let cursor: CXCursor
  var attributes: [CAttribute] = []

  mutating func addAttribute(_ attr: CAttribute) {
    self.attributes.append(attr)
  }
}

enum CAttributeType {
  case annotate
  case unexposed
}

struct CAttribute {
  let name: String
  let type: CAttributeType
  let params: [String]

  init(name: String, type: CAttributeType, params: [String] = []) {
    self.name = name
    self.type = type
    self.params = params
  }
}

struct CTypedef {
  let name: String
  let refersTo: CType
  let origin: CXSourceLocation
}
