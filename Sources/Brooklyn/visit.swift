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
      case CXCursor_ParmDecl:
        return try visitParmDecl(cursor, parent: parent, &clientData.pointee)
      case CXCursor_AnnotateAttr:
        return try visitAnnotateAttr(cursor, parent: parent, &clientData.pointee)
      case CXCursor_TypeRef:
        return CXChildVisit_Continue
      case CXCursor_UnexposedAttr:
        return try visitUnexposedAttr(cursor, parent: parent, &clientData.pointee)
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
      try prog.addTypedef(CTypedef(name: typedefName, refersTo: type, origin: cursor.location))
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

  log("@EnumConstantDecl \(enumName) -> \(enumCaseName) = \(value)")

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
  log("@FunctionDecl \(type) \(name)")
  try prog.addFunction(CFunction(type: type, name: name, origin: cursor.location))

  return CXChildVisit_Recurse // We're not interested in function body
}

func visitParmDecl(_ cursor: CXCursor, parent: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType
  guard let type = CType(cxType: cursorType) else {
    unhandledKind(cursorType.kind, location: cursor.location)
  }
  var name: String? = cursor.spelling!
  if name == "" {
    name = nil
  }
  let functionName = parent.spelling!
  log("@ParmDecl \(functionName) -> \(type) \(name ?? "unnamed")")
  try prog.addParam(to: functionName, CParam(type: type, name: name, cursor: cursor))

  return CXChildVisit_Recurse
}

fileprivate func addAttribute(parentName: String, parent: CXCursor, _ attr: CAttribute, _ prog: inout CProgram) throws {
  switch (parent.kind) {
    case CXCursor_FunctionDecl:
      try prog.addAttribute(toFunction: parentName, attr)
    case CXCursor_ParmDecl:
      let functionName = parent.semanticParent.spelling!
      try prog.addAttribute(toParameter: parent, belongingToFunction: functionName, attr)
    case CXCursor_StructDecl: fallthrough
    case CXCursor_UnionDecl:
      try prog.addAttribute(toRecord: parentName, attr)
    default:
      unhandledKind(parent.kind)
  }
}

func visitAnnotateAttr(_ cursor: CXCursor, parent: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let name = cursor.spelling!
  let parentName = parent.spelling!
  let attr = CAttribute(name: name, type: .annotate)

  log("@AnnotateAttr \(parentName) -> \(name)")
  try addAttribute(parentName: parentName, parent: parent, attr, &prog)

  return CXChildVisit_Continue
}

func visitUnexposedAttr(_ cursor: CXCursor, parent: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
  let parentName = parent.spelling!
  let range = cursor.extent

  var tokens: UnsafeMutablePointer<CXToken>? = nil
  var numTokens: UInt32 = 0
  clang_tokenize(cursor.translationUnit, range, &tokens, &numTokens)
  defer { clang_disposeTokens(cursor.translationUnit, tokens, numTokens) }
  let attr = parseUnexposedAttribute(translationUnit: cursor.translationUnit, fromTokens: tokens!, numTokens: numTokens)

  print("@UnexposedAttr \(parentName) -> \(attr)")
  try addAttribute(parentName: parentName, parent: parent, attr, &prog)

  return CXChildVisit_Continue
}

//func visitTypeRef(_ cursor: CXCursor, parent: CXCursor, _ prog: inout CProgram) throws -> CXChildVisitResult {
//  let cursorType: CXType = cursor.cursorType

//  print("@TypeRef \(cursorType.kind) \(cursorType.spelling!) \(cursor.spelling!) \(parent.spelling!)")

//  switch (cursorType.kind) {
//    case CXType_Record:
//      let recordTypeName = cursor.spelling!
//      log("@TypeRef.Record \(recordTypeName)")
//    default: unhandledKind(cursorType.kind)
//  }

//  return CXChildVisit_Recurse
//}
