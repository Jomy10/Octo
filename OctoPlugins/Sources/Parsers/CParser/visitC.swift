import Foundation
import Clang
import OctoIO
import OctoIntermediate
import OctoParseTypes

var C_PARSING_ERROR: (any Error)? = nil

struct LogOnce {
  static var msgs: Set<String> = Set()

  static func logOnce(_ msg: String, _ level: Logger.Level) {
    if !Self.msgs.contains(msg) {
      clogger.log(level: level, "\(msg)")
      Self.msgs.insert(msg)
    }
  }
}

func visitC(
  _ cursor: CXCursor,
  _ parent: CXCursor,
  _ clientData: CXClientData?
) -> CXChildVisitResult {
  let userData: UnsafeMutablePointer<UserData> = UnsafeMutableRawPointer(clientData!)
    .assumingMemoryBound(to: UserData.self)
  let library = withUnsafeMutablePointer(to: &userData.pointee.library) { $0 }
  let config = userData.pointee.config

  let (file, _, _, _) = cursor.location.expansionLocation
  if !config.headerIncluded(URL(filePath: file.fileName)) {
    LogOnce.logOnce("skipping file \(file.fileName)", .trace)
    return CXChildVisit_Continue
  }

  //let (cursorFileLocation, _, _, _) = cursor.location.expansionLocation
  //if !userData.pointee.config.headerIncluded(URL(filePath: cursorFileLocation.fileName)) {
  //  return CXChildVisit_Continue
  //}

  do {
    let parentType = parent.cursorType
    switch (cursor.kind) {
      case CXCursor_StructDecl:
        if (parentType.kind == CXType_Typedef) { return CXChildVisit_Continue }
        if (parentType.kind != CXType_Invalid) {
          throw ParseError("Unhandled parent type for struct: \(parentType.kind)", origin: .c(cursor.location))
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
      case CXCursor_UnexposedExpr: fallthrough
      case CXCursor_StringLiteral:
        clogger.debug("\(cursor.spelling!) \(cursor.kind.spelling!) \(cursor.cursorType.spelling!)")
        return CXChildVisit_Recurse
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
  clogger.trace("@StructDecl.Record \(recordName)")

  if let obj = lib.getObject(forRef: cursor) as? OctoRecord {
    if obj.ffiName != recordName { throw ParseError("Redefinition with different name", origin: .c(cursor.location)) }
    if obj.type != .`struct` {
      throw ParseError("Redefinition of type \(recordName) with a different type (got \(obj.type), expected struct)", origin: .c(cursor.location))
    }
  } else {
    try lib.addObject(
      OctoRecord(
        origin: .c(cursor.location),
        name: recordName,
        type: .`struct`
      ), ref: cursor
    )
  }

  return CXChildVisit_Recurse
}

fileprivate func visitUnionDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if cursorType.kind != CXType_Record {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let recordName = cursor.spelling!

  clogger.trace("@UnionDecl.Record \(recordName)")

  if let obj = lib.getObject(forRef: cursor) as? OctoRecord {
    if obj.ffiName != recordName { throw ParseError("Redefinition with different name", origin: .c(cursor.location)) }
    if obj.type != .union {
      throw ParseError("Redefinition of type \(recordName) with a different type (got \(obj.type), expected union)", origin: .c(cursor.location))
    }
  } else {
    try lib.addObject(
      OctoRecord(
        origin: .c(cursor.location),
        name: recordName,
        type: .`union`
      ), ref: cursor
    )
  }

  return CXChildVisit_Recurse
}

fileprivate func visitFieldDecl(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let decl = try parseVarDecl(cursor, lib)

  let parentTypeName = parent.spelling!
  guard let parent = lib.getObject(forRef: parent) as? OctoRecord else {
    throw ParseError("Record \(parentTypeName) doesn't exist", origin: .c(cursor.location))
  }
  clogger.trace("@FieldDecl \(parentTypeName) -> \(decl.type) \(decl.name!)")

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

fileprivate func visitTypedefDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if cursorType.kind != CXType_Typedef {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let typedefType = cursor.typedefDeclUnderlyingType
  let typedefName = cursorType.typedefName!
  let type = try OctoType(cxType: typedefType, in: lib, origin: .c(cursor.location))
  clogger.trace("@TypedefDecl.typedef \(typedefName) = \(type)")
  lib.addTypedef(toType: type, name: typedefName)

  //clogger.trace("@TypedefDecl.typedef \(typedefName) = <pending>")
  //try lib.addObject(
  //  OctoTypedef(
  //    origin: .c(cursor.location),
  //    name: typedefName,
  //    refersToDeferred: typeDeferred
  //  ), ref: cursor
  //)

  return CXChildVisit_Recurse
}

fileprivate func visitEnumDecl(_ cursor: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let cursorType: CXType = cursor.cursorType

  if cursorType.kind != CXType_Enum {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let enumName = cursor.spelling!
  var enumDeclIntegerType = try OctoType(cxType: cursor.enumDeclIntegerType, in: lib, origin: .c(cursor.location))
  enumDeclIntegerType.mutable = false

  clogger.trace("@EnumDecl.Enum \(enumDeclIntegerType) \(enumName)")

  if let obj = lib.getObject(forRef: cursor) as? OctoEnum {
    if obj.ffiName != enumName { throw ParseError("Redefinition with different name", origin: .c(cursor.location)) }
    if obj.type != enumDeclIntegerType {
      throw ParseError("Redefinition of enum with different enum integer type", origin: .c(cursor.location))
    }
  } else {
    try lib.addObject(
      OctoEnum(
        origin: .c(cursor.location),
        name: enumName,
        type: enumDeclIntegerType
      ), ref: cursor
    )
  }

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

  clogger.trace("@EnumConstantDecl \(enumName) -> \(enumCaseName) = \(value)")

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
  guard case .Function(callingConv: _, args: _, result: let resultType) = try OctoType(cxType: cursorType, in: lib, origin: .c(cursor.location)).kind else {
    throw ParseError.unhandledKind(cursorType.kind, location: cursor.location)
  }

  let name = cursor.spelling!
  clogger.trace("@FunctionDecl \(name) -> \(resultType)")
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

  clogger.trace("@ParmDecl \(functionName) -> \(type) \(name ?? "unnamed")")
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
  let params = try parseAnnotateAttrParams(translationUnit: cursor.translationUnit, fromTokens: tokens!, numTokens: numTokens)

  clogger.trace("@AnnotateAttr \(parentName) -> \(name) \(String(describing: params))")

  guard let attr = try OctoAttribute(name: name, params: params, in: lib, origin: OctoOrigin.c(cursor.location)) else {
    clogger.warning("Ignored annotate attribute \(name)")
    return CXChildVisit_Continue
  }

  try addAttribute(cursor: cursor, parent: parent, attr, &lib)
  clang_disposeTokens(cursor.translationUnit, tokens, numTokens)

  return CXChildVisit_Recurse
}

fileprivate func visitUnexposedAttr(_ cursor: CXCursor, parent: CXCursor, _ lib: inout OctoLibrary) throws -> CXChildVisitResult {
  let parentName = parent.spelling!
  let range = cursor.extent

  var tokens: UnsafeMutablePointer<CXToken>? = nil
  var numTokens: UInt32 = 0
  clang_tokenize(cursor.translationUnit, range, &tokens, &numTokens)

  var name: String = ""
  guard let attr = try parseUnexposedAttribute(origin: cursor.location, translationUnit: cursor.translationUnit, fromTokens: tokens!, numTokens: numTokens, in: lib, nameIfNil: &name) else {
    clogger.warning("Ignored attribute '\(name)' at \(cursor.location)")
    return CXChildVisit_Continue
  }

  clogger.trace("@UnexposedAttr \(parentName) -> \(attr)")
  try addAttribute(cursor: cursor, parent: parent, attr, &lib)
  clang_disposeTokens(cursor.translationUnit, tokens, numTokens)

  return CXChildVisit_Recurse
}
