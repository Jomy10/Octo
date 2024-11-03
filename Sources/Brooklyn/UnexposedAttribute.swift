import Clang

func parseUnexposedAttribute(
  translationUnit: CXTranslationUnit,
  fromTokens _tokens: UnsafeMutablePointer<CXToken>,
  numTokens: UInt32
) -> CAttribute {
  let tokens = UnsafeMutableBufferPointer<CXToken>(start: _tokens, count: Int(numTokens))
  var name: String? = nil
  var params: [String] = []

  TokenIter: for token in tokens {
    switch (token.kind) {
      case CXToken_Identifier:
        if name != nil {
          fatalError("unexpected identifier token \(String(describing: token.spelling(translationUnit: translationUnit)))")
        }
        name = token.spelling(translationUnit: translationUnit)
      case CXToken_Literal:
        params.append(token.spelling(translationUnit: translationUnit)!)
      case CXToken_Punctuation:
        if token.spelling(translationUnit: translationUnit) == ")" {
          break TokenIter
        }
      default:
        unhandledToken(token, translationUnit: translationUnit)
    }
  }

  return CAttribute(name: name!, type: .unexposed, params: params)
}
