import Foundation
import Clang
import OctoIO

func visitC(
  _ cursor: CXCursor,
  _ parent: CXCursor,
  _ clientData: CXClientData?
) -> CXChildVisitResult {
  let library: UnsafeMutablePointer<OctoLibrary> = UnsafeMutableRawPointer(clientData!)
    .bindMemory(to: OctoLibrary.self, capacity: 1)

  do {
    switch (cursor.kind) {
      case CXCursor_StructDecl:
        return try visitStructDecl(cursor, &library.pointee)
      case CXCursor_FieldDecl:
        return try visitFieldDecl(cursor, parent: parent, &library.pointee)
      case CXCursor_TypedefDecl:
        return try visitTypedefDecl(cursor, &library.pointee)
      case CXCursor_VarDecl:
        return try visitVarDecl(cursor, &library.pointee)
      case CXCursor_EnumDecl:
        return try visitEnumDecl(cursor, &library.pointee)
      case CXCursor_EnumConstantDecl:
        return try visitEnumConstantDecl(cursor, parent: parent, &library.pointee)
      case CXCursor_UnionDecl:
        return try visitUnionDecl(cursor, &library.pointee)
      case CXCursor_FunctionDecl:
        return try visitFunctionDecl(cursor, &library.pointee)
      case CXCursor_ParmDecl:
        return try visitParmDecl(cursor, parent: parent, &library.pointee)
      case CXCursor_AnnotateAttr:
        return try visitAnnotateAttr(cursor, parent: parent, &library.pointee)
      case CXCursor_TypeRef:
        return CXChildVisit_Continue
      case CXCursor_UnexposedAttr:
        return try visitUnexposedAttr(cursor, parent: parent, &library.pointee)
      default: throw ParseError.unhandledKind(cursor.kind, location: cursor.location)
    }
  } catch let error {
    log(error.localizedDescription, .error)
    exit(1)
  }
}

func parseVarDecl(_ cursor: CXCursor) throws -> (
  type: OctoType,
  name: String
) {
  let cursorType: CXType = cursor.cursorType

  guard let varType = try OctoType(cxType: cursorType) else {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }
  let varName = cursor.spelling!

  return (type: varType, name: varName)
}

func visitStructDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if (cursorType.kind != CXType_Record) {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let recordName = cursor.spelling!
  log("@StructDecl.Record \(recordName)")
  lib.addUserType(
    record: OctoRecord(name: recordName, origin: cursor.location.into(), type: .`struct`),
    id: cursor
  )

  return CXChildVisit_Recurse
}

func visitFieldDecl(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let decl = try parseVarDecl(cursor)

  let parentTypeName = parent.spelling!
  guard let parentId = lib.getUserType(lid: parent) else {
    throw ParseError("\(parentTypeName) is unknown", cursor.location)
  }
  log("@FieldDecl \(parentTypeName) -> \(decl.type) \(decl.name)")
  lib.addField(
    to: parentId,
    OctoField(type: decl.type, name: decl.name, origin: cursor.location.into()),
    id: cursor
  )

  // We want the attributes as well
  return CXChildVisit_Recurse
}

func visitVarDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let decl = try parseVarDecl(cursor)

  let global = cursor.hasVarDeclGlobalStorage
  let external = cursor.hasVarDeclExternalStorage

  if !global {
    log("[WARN] Unhandled variable \(decl)", .warning)
    return CXChildVisit_Continue
  }

  log("@VarDecl \(global ? "global " : "")\(external ? "extern " : "")\(decl.type) \(decl.name)")
  lib.addGlobalVariable(
    OctoGlobalVariable(type: decl.type, name: decl.name, external: external, origin: cursor.location.into()),
    id: cursor
  )

  return CXChildVisit_Continue
}

func visitTypedefDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if cursorType.kind != CXType_Typedef {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let typedefType = cursor.typedefDeclUnderlyingType
  guard let type = try OctoType(cxType: typedefType) else {
    throw ParseError.unhandledKind(typedefType.kind, location: cursor.location)
  }

  let typedefName = cursorType.typedefName!
  log("@TypedefDecl.typedef \(typedefName) = \(type)")
  lib.addTypedef(
    OctoTypedef(name: typedefName, refersTo: type, origin: cursor.location.into()),
    id: cursor
  )

  return CXChildVisit_Recurse
}

func visitEnumDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if cursorType.kind != CXType_Enum {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let enumName = cursor.spelling!
  guard let enumDeclIntegerType = try OctoType(cxType: cursor.enumDeclIntegerType) else {
    throw ParseError.unhandledKind(cursor.enumDeclIntegerType.kind, location: cursor.location)
  }

  log("@EnumDecl.Enum \(enumDeclIntegerType) \(enumName)")
  lib.addUserType(
    enum: OctoEnum(type: enumDeclIntegerType, name: enumName, origin: cursor.location.into()),
    id: cursor
  )

  return CXChildVisit_Recurse
}

func visitEnumConstantDecl(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let enumName = parent.spelling!
  let enumCaseName = cursor.spelling!

  guard let parentEnumId = lib.getUserType(lid: parent) else {
    throw ParseError("\(enumName) is unknown", cursor.location)
  }
  guard case .`enum`(let parentEnum) = lib.getUserType(id: parentEnumId)!.inner else {
    throw ParseError("Wrong user type for enum \(enumName)", cursor.location)
  }

  let value: OctoEnumCase.Value
  if parentEnum.type.kind.isSigned! {
    value = .signed(cursor.enumConstantDeclValue)
  } else {
    value = .unsigned(cursor.enumConstantDeclUnsignedValue)
  }

  log("@EnumConstantDecl \(enumName) -> \(enumCaseName) = \(value)")

  lib.addEnumCase(
    to: parentEnumId,
    OctoEnumCase(name: enumCaseName, value: value, origin: cursor.location.into()),
    id: cursor
  )

  return CXChildVisit_Recurse
}

func visitUnionDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if cursorType.kind != CXType_Record {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let recordName = cursor.spelling!

  log("@UnionDecl.Record \(recordName)")

  lib.addUserType(
    record: OctoRecord(name: recordName, origin: cursor.location.into(), type: .`union`),
    id: cursor
  )

  return CXChildVisit_Recurse
}

func visitFunctionDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType
  guard let type = try OctoType(cxType: cursorType) else {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let name = cursor.spelling!
  log("@FunctionDecl \(type) \(name)")
  lib.addFunction(
    OctoFunction(type: type, name: name, origin: cursor.location.into()),
    id: cursor
  )

  return CXChildVisit_Recurse
}

func visitParmDecl(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  guard let type = try OctoType(cxType: cursorType) else {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  var name: String? = cursor.spelling!
  if name == "" {
    name = nil
  }
  let functionName = parent.spelling!

  guard let objectId = lib.getObject(lid: parent) else {
    throw ParseError("\(functionName) is unknown", cursor.location)
  }
  let objectType = lib.getObjectType(id: objectId)!
  if objectType != OctoFunction.self {
    log("visiting ParamDecl: \(functionName) is of type \(objectType), not function. This will be unhandled", .debug)
    return CXChildVisit_Continue
  }

  log("@ParmDecl \(functionName) -> \(type) \(name ?? "unnamed")")
  guard let functionId = lib.getFunction(lid: parent) else {
    throw ParseError("\(functionName) is unknown", cursor.location)
  }
  lib.addParam(
    to: functionId,
    OctoParam(type: type, name: name, origin: cursor.location.into()),
    id: cursor
  )

  return CXChildVisit_Recurse
}

fileprivate func addAttribute(
  cursor: CXCursor,
  parent: CXCursor,
  _ attr: OctoAttribute,
  _ lib: inout OctoLibrary
) throws {
  guard let objectId = lib.getObject(lid: parent) else {
    throw ParseError("\(parent.spelling!) is unknown", cursor.location)
  }

  //print("Add attribute to: \(objectId), \(attr), id: \(cursor)")
  lib.addAttribute(to: objectId, attr, id: cursor)
}

func visitAnnotateAttr(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let name = cursor.spelling!
  let parentName = cursor.spelling!
  let range = cursor.extent

  var tokens: UnsafeMutablePointer<CXToken>? = nil
  var numTokens: UInt32 = 0
  clang_tokenize(cursor.translationUnit, range, &tokens, &numTokens)
  defer { clang_disposeTokens(cursor.translationUnit, tokens, numTokens) }
  let params = try parseAnnotateAttrParams(translationUnit: cursor.translationUnit, fromTokens: tokens!, numTokens: numTokens)

  let attr = OctoAttribute(
    name: name,
    type: .annotate,
    params: params,
    origin: cursor.location.into()
  )

  log("@AnnotateAttr \(parentName) -> \(name) \(String(describing: params))")

  try addAttribute(cursor: cursor, parent: parent, attr, &lib)

  return CXChildVisit_Recurse
}

func visitUnexposedAttr(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let parentName = parent.spelling!
  let range = cursor.extent

  var tokens: UnsafeMutablePointer<CXToken>? = nil
  var numTokens: UInt32 = 0
  clang_tokenize(cursor.translationUnit, range, &tokens, &numTokens)
  defer { clang_disposeTokens(cursor.translationUnit, tokens, numTokens) }
  let attr = try parseUnexposedAttribute(origin: cursor.location, translationUnit: cursor.translationUnit, fromTokens: tokens!, numTokens: numTokens)

  log("@UnexposedAttr \(parentName) -> \(attr)")
  try addAttribute(cursor: cursor, parent: parent, attr, &lib)

  return CXChildVisit_Recurse
}
