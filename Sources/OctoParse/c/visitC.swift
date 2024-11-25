import Foundation
import Clang
import Logging
import OctoIO
import OctoIntermediate

var C_PARSING_ERROR: (any Error)? = nil

func visitC(
  _ cursor: CXCursor,
  _ parent: CXCursor,
  _ clientData: CXClientData?
) -> CXChildVisitResult {
  let library: UnsafeMutablePointer<OctoLibrary> = UnsafeMutableRawPointer(clientData!)
    .bindMemory(to: OctoLibrary.self, capacity: 1)

  do {
    let parentType = parent.cursorType
    switch (cursor.kind) {
      case CXCursor_StructDecl:
        if (parentType.kind == CXType_Typedef) { return CXChildVisit_Continue }
        if (parentType.kind != CXType_Invalid) {
          throw ParseError("Unhandled parent type for struct: \(parentType.kind) ()", origin: .c(cursor.location))
        }
        return try visitStructDecl(cursor, &library.pointee)
      case CXCursor_FieldDecl:
        if parentType.kind != CXType_Record {
          throw ParseError("Field decl on non-record type \(parentType.kind)", origin: .c(cursor.location))
        }
        return try visitFieldDecl(cursor, parent: parent, &library.pointee)
      case CXCursor_TypedefDecl:
        if parentType.kind != CXType_Invalid {
          throw ParseError("Invalid typedef parent \(parentType.kind)", origin: .c(cursor.location))
        }
        return try visitTypedefDecl(cursor, &library.pointee)
      case CXCursor_VarDecl:
        return CXChildVisit_Continue
        //if parentType.kind != CXType_Invalid {
        //  throw ParseError("Invalid variable declaration parent \(parentType.kind)")
        //}
        //return try visitVarDecl(cursor, &library.pointee)
      case CXCursor_EnumDecl:
        if (parentType.kind == CXType_Typedef) { return CXChildVisit_Continue }
        if (parentType.kind != CXType_Invalid) {
          throw ParseError("Invalid enum declaration parent \(parentType.kind)", origin: .c(cursor.location))
        }
        return try visitEnumDecl(cursor, &library.pointee)
      case CXCursor_EnumConstantDecl:
        if parentType.kind != CXType_Enum {
          throw ParseError("Enum constant decl on non-enum type \(parentType.kind)", origin: .c(cursor.location))
        }
        return try visitEnumConstantDecl(cursor, parent: parent, &library.pointee)
      case CXCursor_UnionDecl:
        if (parentType.kind == CXType_Typedef) { return CXChildVisit_Continue }
        if (parentType.kind != CXType_Invalid) {
          throw ParseError("Invalid enum declaration parent \(parentType.kind)", origin: .c(cursor.location))
        }
        return try visitUnionDecl(cursor, &library.pointee)
      case CXCursor_FunctionDecl:
        if parentType.kind != CXType_Invalid {
          throw ParseError("Invalid function declaration parent \(parentType.kind)", origin: .c(cursor.location))
        }
        return try visitFunctionDecl(cursor, &library.pointee)
      case CXCursor_ParmDecl:
        switch (parentType.kind) {
          case CXType_FunctionProto: break // parameter on regular function definition
          case CXType_Pointer: return CXChildVisit_Continue // parameter on a function pointer (e.g. used as variable or function paramter)
          default:
            throw ParseError("Invalid parameter declaration parent \(parentType.kind)", origin: .c(cursor.location))
        }
        return try visitParmDecl(cursor, parent: parent, &library.pointee)
      case CXCursor_AnnotateAttr:
        return try visitAnnotateAttr(cursor, parent: parent, &library.pointee)
      case CXCursor_TypeRef:
        return CXChildVisit_Continue
      case CXCursor_UnexposedAttr:
        return try visitUnexposedAttr(cursor, parent: parent, &library.pointee)
      case CXCursor_UnaryOperator:
        return CXChildVisit_Continue
      case CXCursor_IntegerLiteral:
        return CXChildVisit_Continue
      default:
        throw ParseError.unhandledKind(cursor.kind, location: cursor.location)
    }
  } catch let error {
    C_PARSING_ERROR = error
    return CXChildVisit_Break
  }
}

fileprivate func parseVarDecl(_ cursor: CXCursor, _ lib: OctoLibrary) throws -> (
  type: OctoType,
  name: String?
) {
  let cursorType: CXType = cursor.cursorType

  //let qualifiers = getClangQualifiers(cursor: cursor)

  let varType = try OctoType(cxType: cursorType, in: lib)
  var varName = cursor.spelling
  if varName == "" {
    varName = nil
  }

  //print(varName, qualifiers, varType)

  return (type: varType, name: varName)
}

fileprivate func visitStructDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if (cursorType.kind != CXType_Record) {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let recordName = cursor.spelling!
  octoLogger.trace("@StructDecl.Record \(recordName)")
  try lib.addObject(
    OctoRecord(
      origin: .c(cursor.location),
      name: recordName,
      type: .`struct`
    ), ref: cursor
  )

  return CXChildVisit_Recurse
}

fileprivate func visitUnionDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if cursorType.kind != CXType_Record {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let recordName = cursor.spelling!

  octoLogger.trace("@UnionDecl.Record \(recordName)")

  try lib.addObject(
    OctoRecord(
      origin: .c(cursor.location),
      name: recordName,
      type: .`union`
    ), ref: cursor
  )

  return CXChildVisit_Recurse
}

fileprivate func visitFieldDecl(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let decl = try parseVarDecl(cursor, lib)

  let parentTypeName = parent.spelling!
  guard let parent = lib.getObject(forRef: parent) as? OctoRecord else {
    throw ParseError("Record \(parentTypeName) doesn't exist", origin: .c(cursor.location))
  }
  octoLogger.trace("@FieldDecl \(parentTypeName) -> \(decl.type) \(decl.name!)")

  let field = OctoField(
    origin: .c(cursor.location),
    name: decl.name!,
    type: decl.type
  )
  try lib.addObject(field, ref: cursor)
  parent.addField(field)

  // We want the attributes as well
  return CXChildVisit_Recurse
}

// unused
//func visitVarDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
//  let decl = try parseVarDecl(cursor)

//  let global = cursor.hasVarDeclGlobalStorage
//  let external = cursor.hasVarDeclExternalStorage

//  if !global {
//    octoLogger.warning("Unhandled non-global variable \(decl)")
//    return CXChildVisit_Continue
//  }

//  octoLogger.debug("@VarDecl \(global ? "global " : "")\(external ? "extern " : "")\(decl.type) \(decl.name)")
//  lib.addGlobalVariable(
//    OctoGlobalVariable(type: decl.type, name: decl.name, external: external, origin: cursor.location.into()),
//    id: cursor
//  )

//  return CXChildVisit_Continue
//}

fileprivate func visitTypedefDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if cursorType.kind != CXType_Typedef {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let typedefType = cursor.typedefDeclUnderlyingType
  let type = try OctoType(cxType: typedefType, in: lib)

  let typedefName = cursorType.typedefName!
  octoLogger.trace("@TypedefDecl.typedef \(typedefName) = \(type)")
  try lib.addObject(
    OctoTypedef(
      origin: .c(cursor.location),
      name: typedefName,
      refersTo: type // if this is ._Pending, then it will be filled in later
    ), ref: cursor
  )

  return CXChildVisit_Recurse
}

fileprivate func visitEnumDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if cursorType.kind != CXType_Enum {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let enumName = cursor.spelling!
  var enumDeclIntegerType = try OctoType(cxType: cursor.enumDeclIntegerType, in: lib)
  enumDeclIntegerType.mutable = false

  octoLogger.trace("@EnumDecl.Enum \(enumDeclIntegerType) \(enumName)")
  try lib.addObject(
    OctoEnum(
      origin: .c(cursor.location),
      name: enumName,
      type: enumDeclIntegerType
    ), ref: cursor
  )

  return CXChildVisit_Recurse
}

fileprivate func visitEnumConstantDecl(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let enumName = parent.spelling!
  let enumCaseName = cursor.spelling!

  guard let enumObj = lib.getObject(forRef: parent) as? OctoEnum else {
    throw ParseError("Enum \(enumName) not known")
  }

  let value: OctoEnumCase.Value
  if enumObj.type.kind.isSignedInt! {
    value = .int(cursor.enumConstantDeclValue)
  } else {
    value = .uint(cursor.enumConstantDeclUnsignedValue)
  }

  octoLogger.trace("@EnumConstantDecl \(enumName) -> \(enumCaseName) = \(value)")

  let ec = OctoEnumCase(
    origin: .c(cursor.location),
    name: enumCaseName,
    value: value
  )
  try lib.addObject(ec, ref: cursor)
  enumObj.addCase(ec)

  return CXChildVisit_Recurse
}

fileprivate func visitFunctionDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType
  guard case .Function(callingConv: _, args: _, result: let resultType) = try OctoType(cxType: cursorType, in: lib).kind else {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let name = cursor.spelling!
  octoLogger.trace("@FunctionDecl \(name) -> \(resultType)")
  try lib.addObject(
    OctoFunction(
      origin: .c(cursor.location),
      name: name,
      returnType: resultType
    ), ref: cursor
  )

  return CXChildVisit_Recurse
}

fileprivate func visitParmDecl(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let (type: type, name: name) = try parseVarDecl(cursor, lib)

  let functionName = parent.spelling!

  guard let function = lib.getObject(forRef: parent) as? OctoFunction else {
    throw ParseError("Function \(functionName) not defined", origin: .c(cursor.location))
  }

  octoLogger.trace("@ParmDecl \(functionName) -> \(type) \(name ?? "unnamed")")
  let arg = OctoArgument(
    origin: .c(cursor.location),
    name: name,
    type: type
  )
  try lib.addObject(arg, ref: cursor)
  function.addArgument(arg)

  return CXChildVisit_Recurse
}

fileprivate func addAttribute(
  cursor: CXCursor,
  parent: CXCursor,
  _ attr: OctoAttribute,
  _ lib: inout OctoLibrary
) throws {
  guard let object = lib.getObject(forRef: parent) else {
    throw ParseError("Object \(parent.spelling!) is not defined", origin: .c(cursor.location))
  }

  try object.addAttribute(attr)
}

fileprivate func visitAnnotateAttr(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let name = cursor.spelling!
  let parentName = cursor.spelling!
  let range = cursor.extent

  var tokens: UnsafeMutablePointer<CXToken>? = nil
  var numTokens: UInt32 = 0
  clang_tokenize(cursor.translationUnit, range, &tokens, &numTokens)
  defer { clang_disposeTokens(cursor.translationUnit, tokens, numTokens) }
  let params = try parseAnnotateAttrParams(translationUnit: cursor.translationUnit, fromTokens: tokens!, numTokens: numTokens)

  octoLogger.trace("@AnnotateAttr \(parentName) -> \(name) \(String(describing: params))")

  guard let attr = try OctoAttribute(name: name, params: params, in: lib, origin: OctoOrigin.c(cursor.location)) else {
    octoLogger.warning("Ignored annotate attribute \(name)")
    return CXChildVisit_Continue
  }

  try addAttribute(cursor: cursor, parent: parent, attr, &lib)

  return CXChildVisit_Recurse
}

fileprivate func visitUnexposedAttr(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let parentName = parent.spelling!
  let range = cursor.extent

  var tokens: UnsafeMutablePointer<CXToken>? = nil
  var numTokens: UInt32 = 0
  clang_tokenize(cursor.translationUnit, range, &tokens, &numTokens)
  defer { clang_disposeTokens(cursor.translationUnit, tokens, numTokens) }
  var name: String = ""
  guard let attr = try parseUnexposedAttribute(origin: cursor.location, translationUnit: cursor.translationUnit, fromTokens: tokens!, numTokens: numTokens, in: lib, nameIfNil: &name) else {
    octoLogger.warning("Ignored attribute '\(name)' at \(cursor.location)")
    return CXChildVisit_Continue
  }

  octoLogger.trace("@UnexposedAttr \(parentName) -> \(attr)")
  try addAttribute(cursor: cursor, parent: parent, attr, &lib)

  return CXChildVisit_Recurse
}
