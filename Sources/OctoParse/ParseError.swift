import OctoIntermediate

public struct ParseError: Error {
  let message: String
  var origin: OctoOrigin? = nil

  let thrownAt: (file: String, function: String, line: UInt, column: UInt)

  init(
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
