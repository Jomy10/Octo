import Clang
import OctoIntermediate
import OctoParseTypes

// Attributes //

extension OctoAttribute.Parameter {
  public init?(parsing param: String) {
    if param.hasPrefix("\"") && param.hasSuffix("\"") && !param.hasSuffix("\\\"") {
      let stringStart = param.index(param.startIndex, offsetBy: 1)
      let stringEnd = param.index(param.endIndex, offsetBy: -1)
      self = .string(String(param[stringStart..<stringEnd]))
    } else if let i = Int(param) {
      self = .int(i)
    } else if let d = Double(param) {
      self = .double(d)
    } else {
      clogger.critical("Couldn't parse parameter '\(param)' to a string, integer or double (bug)")
      return nil
    }
  }
}

func parseUnexposedAttribute(
  origin: CXSourceLocation,
  translationUnit: CXTranslationUnit,
  fromTokens _tokens: UnsafeMutablePointer<CXToken>,
  numTokens: UInt32,
  in lib: OctoLibrary,
  nameIfNil: inout String
) throws -> OctoAttribute? {
  let tokens = UnsafeMutableBufferPointer<CXToken>(start: _tokens, count: Int(numTokens))
  var name: String? = nil
  var params: [OctoAttribute.Parameter] = []

  TokenIter: for token in tokens {
    switch (token.kind) {
      case CXToken_Identifier:
        if name != nil {
          throw ParseError("unexpected identifier token \(String(describing: token.spelling(translationUnit: translationUnit)))", origin: .c(origin))
        }
        name = token.spelling(translationUnit: translationUnit)
      case CXToken_Literal:
        params.append(.init(parsing: token.spelling(translationUnit: translationUnit)!)!)
      case CXToken_Punctuation:
        if token.spelling(translationUnit: translationUnit) == ")" {
          break TokenIter
        }
      default:
        throw ParseError.unhandledToken(token, translationUnit: translationUnit)
    }
  }

  nameIfNil = name!
  return try OctoAttribute(
    name: name!,
    params: params,
    in: lib,
    origin: .c(origin)
  )
}

func parseAnnotateAttrParams(
  translationUnit: CXTranslationUnit,
  fromTokens _tokens: UnsafeMutablePointer<CXToken>,
  numTokens: UInt32
) throws -> [OctoAttribute.Parameter] {
  let tokens = UnsafeMutableBufferPointer<CXToken>(start: _tokens, count: Int(numTokens))
  var params: [OctoAttribute.Parameter] = []

  TokenIter: for token in tokens {
    switch (token.kind) {
      case CXToken_Identifier:
        if token.spelling(translationUnit: translationUnit)! != "annotate" {
          throw ParseError("unexpected identifier token \(String(describing: token.spelling(translationUnit: translationUnit)))", origin: .c(token.sourceLocation(translationUnit: translationUnit)))
        }
      case CXToken_Literal:
        params.append(.init(parsing: token.spelling(translationUnit: translationUnit)!)!)
      case CXToken_Punctuation:
        if token.spelling(translationUnit: translationUnit) == ")" {
          break TokenIter
        }
      default:
        throw ParseError.unhandledToken(token, translationUnit: translationUnit)
    }
  }

  params.removeFirst()

  return Array(params)
}

// Type Qualifiers //
// https://stackoverflow.com/a/12131083/14874405

typealias ClangTypeQualifiers = (const: Bool, volatile: Bool, restrict: Bool)

// TODO: there has to be a better way
// https://stackoverflow.com/a/76522031/14874405
@available(*, deprecated)
func getClangQualifiers(cursor: CXCursor) -> ClangTypeQualifiers {
  let prettyPrint = cursor.prettyPrint(cursor.printingPolicy).managed
  let str = prettyPrint.str!
  let constRegex = try! Regex("(^const | const )")
  if str.contains(constRegex) {
    return (const: true, volatile: false, restrict: false)
  } else {
    return (const: false, volatile: false, restrict: false)
  }
}
