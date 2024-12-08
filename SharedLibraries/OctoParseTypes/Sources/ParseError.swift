import OctoIntermediate

public struct ParseError: Error {
  let message: String
  var origin: OctoOrigin? = nil

  let thrownAt: (file: String, function: String, line: UInt, column: UInt)

  public init(
    _ message: String,
    origin: OctoOrigin? = nil,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column
  ) {
    self.message = message
    self.origin = origin

    self.thrownAt = (
      file: file,
      function: function,
      line: line,
      column: column
    )
  }
}

extension ParseError: CustomStringConvertible {
  public var description: String {
    var msg = "ParseError: \(self.message)"
    if let origin = origin {
      msg += " @ \(origin)"
    }
    #if DEBUG || OCTO_DEBUGINFO
    msg += " (originated at \(self.thrownAt))"
    #endif
    return msg
  }
}
