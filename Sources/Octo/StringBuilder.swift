@resultBuilder
struct StringBuilder {
  static func buildBlock(_ parts: String...) -> String {
    return parts.joined(separator: "\n")
  }

  static func buildBlock(_ parts: [String]...) -> String {
    return parts.map { $0.joined(separator: "\n") }.joined(separator: "\n")
  }

  static func buildEither(first component: String) -> String {
    return component
  }

  static func buildEither(first component: [String]) -> String {
    return component.joined(separator: "\n")
  }

  static func buildEither(second component: String) -> String {
    return component
  }

  static func buildEither(second component: [String]) -> String {
    return component.joined(separator: "\n")
  }

  static func buildArray(_ components: [String]) -> String {
    return components.joined(separator: "\n")
  }

  static func buildExpression(_ expression: String) -> String {
    return expression
  }

  static func buildOptional(_ component: String?) -> String {
    return component ?? ""
  }

  static func buildLimitedAvailability(_ component: String) -> String {
    return component
  }
}
