import ExpressionInterpreter

extension ParseError: CustomStringConvertible {
  public var description: String {
    "ExpressionParseError: " + self.toString()
  }
}

extension ExecutionError: CustomStringConvertible {
  public var description: String {
    "ExpressionExecutionError: " + self.toString()
  }
}
