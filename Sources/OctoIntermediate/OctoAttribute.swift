fileprivate func checkParameterCount(min: Int, max: Int, _ name: some StringProtocol, _ count: Int, isAnnotate: Bool = true, origin: OctoOrigin?) throws {
  if !(count >= min && count <= max) {
    throw AttributeError("Expected \(min) to \(max) arguments in \(isAnnotate ? "annotate " : "")attribute '\(name)' (got \(count))", origin: origin)
  }
}

fileprivate func checkParameterCount(_ exact: Int, _ name: some StringProtocol, _ count: Int, isAnnotate: Bool = true, origin: OctoOrigin?) throws {
  if (count != exact) {
    throw AttributeError("Expected \(exact) argument\(exact == 1 ? "" : "s") in \(isAnnotate ? "annotate " : "")attribute '\(name)' (got \(count))", origin: origin)
  }
}

public enum OctoAttribute {
  case rename(to: String)
  case attach(to: any OctoFunctionAttachable, type: OctoFunction.FunctionType)
  case nonnull
  case nullable
  case returnsNonNull

  public enum Parameter {
    case string(String)
    case int(Int)
    case double(Double)
  }

  public init?(
    name: some StringProtocol,
    params: [Parameter],
    in lib: OctoLibrary,
    origin: OctoOrigin? = nil
  ) throws {
    switch (name) {
      case "attach":
        try checkParameterCount(min: 1, max: 2, name, params.count, origin: origin)
        guard case .string(let attachToName) = params[0] else {
          throw AttributeError("Expected first parameter of 'attach' to be a string, got: \(params[0])", origin: origin)
        }
        var type: OctoFunction.FunctionType? = nil
        if params.count >= 2 {
          try params[1...].enumerated().forEach { (i, rawParam) in
            guard case .string(let param) = rawParam else {
              throw AttributeError("Expected parameter \(i + 1) of attribute 'attach' to be a string, got: \(rawParam)")
            }
            let s = param.split(separator: ":", maxSplits: 1)
            if s.count != 2 {
              throw AttributeError("Malformed argument (expected [name]:[value], got: \"\(param)\")", origin: origin)
            }

            switch (s[0]) {
              case "type": type = OctoFunction.FunctionType(fromArgument: String(s[1]))
              default:
                throw AttributeError("Invalid argument for 'attach' attribute '\(s[0])'", origin: origin)
            }
          }
        }
        // Get the object we want to attach to
        var obj: OctoObject
        if let typedef = lib.getObject(byName: attachToName) as? OctoTypedef { // get inner object from typedef
          obj = try _typedefInnerObject(typedef, origin: origin)
          while let typedef = obj as? OctoTypedef {
            obj = try _typedefInnerObject(typedef, origin: origin)
          }
        } else {
          guard let obj2 = lib.getObject(byName: attachToName) else {
            throw AttributeError("Cannot attach function to \"\(attachToName)\": object doesn't exist", origin: origin)
          }
          obj = obj2
        }
        if let fnAttachable = obj as? (any OctoFunctionAttachable) {
          self = .attach(to: fnAttachable, type: type ?? .method)
        } else {
          throw AttributeError("Cannot attach function to \(attachToName) (\(obj))", origin: origin)
        }
      case "rename":
        try checkParameterCount(1, name, params.count, origin: origin)
        guard case .string(let newName) = params[0] else {
          throw AttributeError("Expected first argument of attribute 'rename' to be a string, got: \(params[0])", origin: origin)
        }
        self = .rename(to: newName)
      case "nonnull":
        try checkParameterCount(0, name, params.count, origin: origin)
        self = .nonnull
      case "nullable":
        try checkParameterCount(0, name, params.count, origin: origin)
        self = .nullable
      case "returns_nonnull":
        try checkParameterCount(0, name, params.count, origin: origin)
        self = .returnsNonNull
      default:
        return nil
    }
  }
}

@inline(__always)
fileprivate func _typedefInnerObject(_ typedef: OctoTypedef, origin: OctoOrigin?) throws -> OctoObject {
  switch (typedef.refersTo.kind) {
    case .Record(let record): return record
    case .Enum(let e): return e
    default:
      throw AttributeError("Cannot attach function to \(typedef.refersTo.kind)", origin: origin)
  }
}

public struct AttributeError: Error {
  let message: String
  let origin: OctoOrigin?

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
