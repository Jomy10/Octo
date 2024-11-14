import Clang

func parseUnexposedAttribute(
  origin: CXSourceLocation,
  translationUnit: CXTranslationUnit,
  fromTokens _tokens: UnsafeMutablePointer<CXToken>,
  numTokens: UInt32
) throws -> OctoAttribute {
  let tokens = UnsafeMutableBufferPointer<CXToken>(start: _tokens, count: Int(numTokens))
  var name: String? = nil
  var params: [OctoAttribute.Parameter] = []

  TokenIter: for token in tokens {
    switch (token.kind) {
      case CXToken_Identifier:
        if name != nil {
          throw ParseError("unexpected identifier token \(String(describing: token.spelling(translationUnit: translationUnit)))", origin)
        }
        name = token.spelling(translationUnit: translationUnit)
      case CXToken_Literal:
        params.append(.init(token.spelling(translationUnit: translationUnit)!)!)
      case CXToken_Punctuation:
        if token.spelling(translationUnit: translationUnit) == ")" {
          break TokenIter
        }
      default:
        throw unhandledToken(token, translationUnit: translationUnit)
    }
  }

  return OctoAttribute(name: name!, type: .unexposed, params: params, origin: origin.into())
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
          throw ParseError("unexpected identifier token \(String(describing: token.spelling(translationUnit: translationUnit)))", token.sourceLocation(translationUnit: translationUnit))
        }
      case CXToken_Literal:
        params.append(.init(token.spelling(translationUnit: translationUnit)!)!)
      case CXToken_Punctuation:
        if token.spelling(translationUnit: translationUnit) == ")" {
          break TokenIter
        }
      default:
        throw unhandledToken(token, translationUnit: translationUnit)
    }
  }

  params.removeFirst()

  return Array(params)
}
