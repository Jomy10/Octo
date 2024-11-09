import Clang

func parseUnexposedAttribute(
  origin: CXSourceLocation,
  translationUnit: CXTranslationUnit,
  fromTokens _tokens: UnsafeMutablePointer<CXToken>,
  numTokens: UInt32
) -> OctoAttribute {
  let tokens = UnsafeMutableBufferPointer<CXToken>(start: _tokens, count: Int(numTokens))
  var name: String? = nil
  var params: [OctoAttribute.Parameter] = []

  TokenIter: for token in tokens {
    switch (token.kind) {
      case CXToken_Identifier:
        if name != nil {
          fatalError("unexpected identifier token \(String(describing: token.spelling(translationUnit: translationUnit)))")
        }
        name = token.spelling(translationUnit: translationUnit)
      case CXToken_Literal:
        params.append(.init(token.spelling(translationUnit: translationUnit)!)!)
      case CXToken_Punctuation:
        if token.spelling(translationUnit: translationUnit) == ")" {
          break TokenIter
        }
      default:
        unhandledToken(token, translationUnit: translationUnit)
    }
  }

  return OctoAttribute(name: name!, type: .unexposed, params: params, origin: origin.into())
}

func parseAnnotateAttrParams(
  translationUnit: CXTranslationUnit,
  fromTokens _tokens: UnsafeMutablePointer<CXToken>,
  numTokens: UInt32
) -> [OctoAttribute.Parameter] {
  let tokens = UnsafeMutableBufferPointer<CXToken>(start: _tokens, count: Int(numTokens))
  var params: [OctoAttribute.Parameter] = []

  TokenIter: for token in tokens {
    switch (token.kind) {
      case CXToken_Identifier:
        if token.spelling(translationUnit: translationUnit)! != "annotate" {
          fatalError("unexpected identifier token \(String(describing: token.spelling(translationUnit: translationUnit)))")
        }
      case CXToken_Literal:
        params.append(.init(token.spelling(translationUnit: translationUnit)!)!)
      case CXToken_Punctuation:
        if token.spelling(translationUnit: translationUnit) == ")" {
          break TokenIter
        }
      default:
        unhandledToken(token, translationUnit: translationUnit)
    }
  }

  params.removeFirst()

  return Array(params)
}
