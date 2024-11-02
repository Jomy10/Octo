import Clang

func visit(
  _ cursor: CXCursor,
  _ parent: CXCursor,
  _ _clientData: CXClientData?
) -> CXChildVisitResult {
  let clientData: UnsafeMutablePointer<CProgram> = UnsafeMutableRawPointer(_clientData!).bindMemory(to: CProgram.self, capacity: 0)

  do {
    switch (cursor.kind) {
      case CXCursor_StructDecl:
        return try visitStructDecl(cursor, &clientData.pointee)
      case CXCursor_FieldDecl:
        return try visitFieldDecl(cursor, parent: parent, &clientData.pointee)
      case CXCursor_TypedefDecl:
        return try visitTypedefDecl(cursor, &clientData.pointee)
      case CXCursor_VarDecl:
        return try visitVarDecl(cursor, &clientData.pointee)
      case CXCursor_EnumDecl:
        return try visitEnumDecl(cursor, &clientData.pointee)
      case CXCursor_EnumConstantDecl:
        return try visitEnumConstantDecl(cursor, parent: parent, &clientData.pointee)
      case CXCursor_UnionDecl:
        return try visitUnionDecl(cursor, &clientData.pointee)
      case CXCursor_FunctionDecl:
        return try visitFunctionDecl(cursor, &clientData.pointee)
      //case CXCursor_TypeRef:
      //  visitTypeRef(cursor)
      default: unhandledKind(cursor.kind)
    }
  } catch let error {
    print("Error")
    print("=====")
    print(error)
    print(clientData)
    return CXChildVisit_Break
  }
}

// Variable and field decl
func parseVarDecl(_ cursor: CXCursor) -> (
  type: CType,
  name: String
) {
  let cursorType: CXType = cursor.cursorType

  guard let varType = CType(cxType: cursorType) else {
    unhandledKind(cursorType.kind, location: cursor.location)
  }
  let varName = cursor.spelling!

  return (type: varType, name: varName)
}

func parseRecord(_ cursor: CXCursor) -> String {
  return cursor.spelling!
}

func visitStructDecl(_ cursor: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  switch (cursorType.kind) {
    case CXType_Record:
      //let recordTypeName = cursor.spelling!
      let recordTypeName = parseRecord(cursor)
      log("@StructDecl.Record \(recordTypeName)")
      try prog.addUserType(.struct(CRecord(name: recordTypeName, origin: cursor.location)))
      return CXChildVisit_Recurse
    default: unhandledKind(cursorType.kind)
  }
}

func visitFieldDecl(_ cursor: CXCursor, parent: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let decl = parseVarDecl(cursor)

  let parentStructName = parent.spelling!
  log("@FieldDecl \(parentStructName) -> \(decl.type) \(decl.name)")
  try prog.addField(to: parentStructName, CField(type: decl.type, name: decl.name))

  return CXChildVisit_Continue
}

func visitTypedefDecl(_ cursor: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  switch (cursorType.kind) {
    case CXType_Typedef:
      let typedefType = cursor.typedefDeclUnderlyingType
      guard let type = CType(cxType: typedefType) else {
        unhandledKind(typedefType.kind)
      }
      let typedefName = cursorType.typedefName!
      log("@TypedefDecl.Typedef \(typedefName) = \(type)")
      try prog.addTypedef(typedefName, type)
      return CXChildVisit_Continue
    default: unhandledKind(cursorType.kind)
  }
}

func visitVarDecl(_ cursor: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let decl = parseVarDecl(cursor)

  //let initializer = cursor.varDeclInitializer
  let global = cursor.hasVarDeclGlobalStorage
  let external = cursor.hasVarDeclExternalStorage

  if !global {
    fatalError("Unhandled variable \(decl)")
  }

  log("@VarDecl \(global ? "global " : "")\(external ? "extern " : "")\(decl.type) \(decl.name)")
  try prog.addGlobalVariable(CVariable(type: decl.type, name: decl.name, external: external, origin: cursor.location))

  return CXChildVisit_Continue
}

func visitEnumDecl(_ cursor: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  switch (cursorType.kind) {
    case CXType_Enum:
      let enumName = cursor.spelling!
      guard let enumDeclIntegerType = CType(cxType: cursor.enumDeclIntegerType) else {
        unhandledKind(cursor.enumDeclIntegerType.kind)
      }
      log("@EnumDecl.Enum \(enumDeclIntegerType) \(enumName)")
      try prog.addUserType(.enum(CEnum(type: enumDeclIntegerType, name: enumName, origin: cursor.location)))
      return CXChildVisit_Recurse
    default: unhandledKind(cursorType.kind)
  }
}

func visitEnumConstantDecl(_ cursor: CXCursor, parent: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  //let cursorType: CXType = cursor.cursorType

  let enumName = parent.spelling!
  let enumCaseName = cursor.spelling!

  let value: CEnumConstant.Value
  guard case .enum(let parentEnum) = prog.getUserType(enumName) else {
    fatalError("Parent is not an enum \(String(describing: prog.getUserType(enumName)))")
  }
  if parentEnum.isSigned {
    value = .signed(cursor.enumConstantDeclValue)
  } else {
    value = .unsigned(cursor.enumConstantDeclUnsignedValue)
  }

  log("@EnumConstantDecl \(enumCaseName) = \(value)")

  try prog.addEnumConstant(to: enumName, CEnumConstant(name: enumCaseName, value: value))

  return CXChildVisit_Continue
}

func visitUnionDecl(_ cursor: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  switch (cursorType.kind) {
    case CXType_Record:
      //let recordTypeName = cursor.spelling!
      let recordTypeName = parseRecord(cursor)
      log("@UnionDecl.Record \(recordTypeName)")
      try prog.addUserType(.union(CRecord(name: recordTypeName, origin: cursor.location)))
      return CXChildVisit_Recurse
    default: unhandledKind(cursorType.kind)
  }
}

func visitFunctionDecl(_ cursor: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType
  guard let type = CType(cxType: cursorType) else {
    unhandledKind(cursorType.kind, location: cursor.location)
  }
  let name = cursor.spelling!
  try prog.addFunction(CFunction(type: type, name: name))

  return CXChildVisit_Continue // We're not interested in function body
}

//func visitTypeRef(_ cursor: CXCursor) {
//  let cursorType: CXType = cursor.cursorType

//  switch (cursorType.kind) {
//    case CXType_Record:
//      let recordTypeName = cursor.spelling!
//      log("@TypeRef.Record \(recordTypeName)")
//    default: unhandledKind(cursorType.kind)
//  }
//}

struct CType: CustomStringConvertible, Equatable {
  private let inner: CXType
  let kind: CTypeKind
  var isConst: Bool {
    self.inner.isConstQualifiedType
  }

  init?(cxType: CXType) {
    guard let kind = CTypeKind(cxType: cxType) else {
      return nil
    }
    self.kind = kind
    self.inner = cxType
  }

  var description: String {
    "\(self.isConst ? "const " : "")\(self.kind)"
  }

  public static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.inner == rhs.inner
  }
}

enum CTypeKind: Equatable {
  case Invalid
  case Void
  case Bool
  case Char_U
  case UChar // unsigned char
  case Char16
  case Char32
  case UShort
  case UInt
  case ULong
  case ULongLong
  case UInt128
  case Char_S // char
  case SChar // signed char
  case WChar
  case Short
  case Int
  case Long
  case LongLong
  case Int128
  case Float
  case Double
  case LongDouble
  indirect case Pointer(to: CType)
  indirect case LValueReference(to: CType)
  indirect case RValueReference(to: CType)
  /// for calling convention see [https://clang.llvm.org/doxygen/group__CINDEX__TYPES.html#ga4a0e941ec7b4b64bf9eb3d0ed49d55ae]
  indirect case FunctionProto(callingConv: CXCallingConv, args: [CType], result: CType)
  indirect case ConstantArray(type: CType, size: Int64)
  case Elaborated(name: Substring, prefix: String? = nil)
}

extension CTypeKind {
  init?(cxType: CXType) {
    switch (cxType.kind) {
      case CXType_Invalid: self = .Invalid
      case CXType_Void: self = .Void
      case CXType_Bool: self = .Bool
      case CXType_Char_U: self = .Char_U
      case CXType_UChar: self = .UChar
      case CXType_Char16: self = .Char16
      case CXType_Char32: self = .Char32
      case CXType_UShort: self = .UShort
      case CXType_UInt: self = .UInt
      case CXType_ULong: self = .ULong
      case CXType_ULongLong: self = .ULongLong
      case CXType_UInt128: self = .UInt128
      case CXType_Char_S: self = .Char_S
      case CXType_SChar: self = .SChar
      case CXType_WChar: self = .WChar
      case CXType_Short: self = .Short
      case CXType_Int: self = .Int
      case CXType_Long: self = .Long
      case CXType_LongLong: self = .LongLong
      case CXType_Int128: self = .Int128
      case CXType_Float: self = .Float
      case CXType_Double: self = .Double
      case CXType_LongDouble: self = .LongDouble
      case CXType_Pointer:
        guard let type = CType(cxType: cxType.pointeeType) else { unhandledKind(cxType.pointeeType.kind) }
        self = .Pointer(to: type)
      case CXType_LValueReference: // &
        guard let type = CType(cxType: cxType.pointeeType) else { unhandledKind(cxType.pointeeType.kind) }
        self = .LValueReference(to: type)
      case CXType_RValueReference: // &&
        guard let type = CType(cxType: cxType.pointeeType) else { unhandledKind(cxType.pointeeType.kind) }
        self = .RValueReference(to: type)
      case CXType_FunctionProto:
        guard let resultType = CType(cxType: cxType.resultType) else { unhandledKind(cxType.resultType.kind) }
        let callingConv = cxType.functionTypeCallingConv
        let argTypes = cxType.argTypes.map { cxt in
          guard let ty = CType(cxType: cxt) else {
            unhandledKind(cxt.kind)
          }
          return ty
        }
        self = .FunctionProto(callingConv: callingConv, args: argTypes, result: resultType)
      case CXType_Elaborated:
        let parts = cxType.spelling!.split(separator: " ")
        self = .Elaborated(name: parts.last!, prefix: parts.count > 1 ? parts[0..<parts.count-1].joined(separator: " "): nil)
      case CXType_ConstantArray:
        guard let type = CType(cxType: clang_getArrayElementType(cxType)) else {
          unhandledKind(clang_getArrayElementType(cxType).kind)
        }
        let size: Int64 = clang_getArraySize(cxType)
        self = .ConstantArray(type: type, size: size)
      default:
        return nil
    }
  }
}
