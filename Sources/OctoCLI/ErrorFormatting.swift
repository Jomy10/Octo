import TOMLKit

extension Swift.DecodingError: CustomStringConvertible {
  private var errorTypeMsg: String {
    switch (self) {
      case .typeMismatch: return "type mismatch"
      case .keyNotFound: return "key not found"
      case .valueNotFound: return "value not found"
      case .dataCorrupted: return "data corrupted"
      default: return "unhandled error (bug)"
    }
  }

  private func formatCtx(_ ctx: DecodingError.Context) -> String {
    var msg = """
     \(self.errorTypeMsg) at path '\(ctx.codingPath.map { path in path.stringValue }
      .joined(separator: "."))'
    """
    msg += ": \(ctx.debugDescription)"
    if let err = ctx.underlyingError {
      msg += "\n  caused by: \(err)"
    }
    return msg
  }

  public var description: String {
    switch (self) {
      case .dataCorrupted(let ctx):
        return """
        Error parsing TOML: data corrupted: \(self.formatCtx(ctx))
        """
      case .keyNotFound(let key, let ctx):
        var msg = "Error paring TOML: key not found '\(key.stringValue)'"
        msg += self.formatCtx(ctx)
        return msg
      case .typeMismatch(let type, let ctx): fallthrough
      case .valueNotFound(let type, let ctx):
        var msg = "Error parsing TOML:"
        _ = type
        //if type == TOMLKit.TOMLTable.self {
        //  msg += "Error parsing TOML:"
        //}
        msg += self.formatCtx(ctx)
        return msg
      default: return "unhandled error (bug)"
    }
  }
}

extension TOMLKit.UnexpectedKeysError: CustomStringConvertible {
  public var description: String {
    let keys = self.keys.map { k, v in
      "'\(k)' at \(v.map { "\($0.stringValue)" }.joined(separator: "."))"
    }
    return "Error parsing TOML: unexpected key\(keys.count == 1 ? "" : "s"): \(keys.joined(separator: ", "))"
  }
}
