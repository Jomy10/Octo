import OctoIntermediate
import OctoGenerateShared

extension OctoFunction: RubyCodeGenerator {
  ///// Part of the function body of an initializer: sets the @ptr instance variable
  //func generateRubyInitializerSetPtr(selfType: OctoRecord, ffiModuleName: String) throws -> String {
  //  assert(self.kind == .initializer)
  //  switch (self.initializerType) {
  //    case .selfArgument:
  //    var passedArgs: Array<String> = Array()
  //    passedArgs.reserveCapacity(self.arguments.count)
  //    var id = 0
  //    for i in 0..<self.arguments.count {
  //      if i == self.selfArgumentIndex! {
  //        passedArgs.append("@ptr")
  //      } else {
  //        passedArgs.append("args[\(id)]")
  //        id += 1
  //      }
  //    }
  //    return """
  //    @ptr = \(ffiModuleName)::\(selfType.rubyFFIName).new
  //    \(ffiModuleName).\(self.rubyFFIName)(\(passedArgs.joined(separator: ", ")))
  //    """
  //    case .returnsSelf:
  //      return "@ptr = \(ffiModuleName).\(self.rubyFFIName)(\((0..<self.arguments.count).map { "args[\($0)]" }.joined(separator: ", ")))"
  //    case .none: throw GenerationError("Unexpected error: found 'none' initializer type for initializer \(self.ffiName!)", .ruby, origin: self.origin)
  //  }
  //}

  @available(*, deprecated)
  static func generateRubyBindingInitializersCode(
    for selfType: OctoRecord,
    //_ initializers: [OctoFunction],
    hasDeinit: Bool,
    options: GenerationOptions,
    in lib: OctoLibrary,
    ffiModuleName: String
  ) throws -> String {
    try generateRubyBindingInitializersCode(for: selfType, options: options, ffiModuleName: ffiModuleName)
  }

  static func generateRubyBindingInitializersCode(
    for selfType: OctoRecord,
    options: GenerationOptions,
    //in lib: OctoLibrary,
    ffiModuleName: String
  ) throws -> String {
    try RubyInitializerBuilder.build(
      for: selfType,
      options: options,
      //in: lib,
      ffiModuleName: ffiModuleName
    )
  }

  // TODO: fix for unions!!
  //static func generateRubyBindingInitializersCode(
  //  for selfType: OctoRecord,
  //  //_ initializers: [OctoFunction],
  //  hasDeinit: Bool,
  //  options: GenerationOptions,
  //  in lib: OctoLibrary,
  //  ffiModuleName: String
  //) throws -> String {
  //  let initializers = selfType.initializers
  //  let defDeinit = "ObjectSpace.define_finalizer(self, DESTROY)"
  //  if initializers.count == 1 || initializers.count == 0 {
  //    let constructNew: String
  //    if initializers.count == 1 {
  //      //constructNew = "\(ffiModuleName).\(initializers[0].ffiName!)(\((0..<initializers[0].arguments.count).map { "args[\($0)]" }.joined(separator: ", ")))"
  //      constructNew = try initializers[0].generateRubyInitializerSetPtr(selfType: selfType, ffiModuleName: ffiModuleName)
  //    } else {
  //      constructNew = """
  //      @ptr = \(ffiModuleName)::\(selfType.rubyFFIName).new
  //      if args.count != 0
  //      \(selfType.fields.enumerated().map { (i, field) in
  //        "\(options.indent)@ptr[:\(field.ffiName!)] = args[\(i)]"
  //      }.joined(separator:" \n"))
  //      end
  //      """
  //    }
  //    //return initializers[0].generateRubyBindingCode(options: options, in: lib, ffiModuleName: ffiModuleName)
  //    return """
  //    def initialize *args
  //    \(indentCode(indent: options.indent, {
  //      if hasDeinit {
  //        defDeinit
  //      }
  //      """
  //      if args.count == 1 && args.first.is_a?(Hash) && args.first.size == 1 && args.first[:fromRawPtr] != nil
  //      \(indentCode(indent: options.indent, {
  //        "@ptr = args.first[:fromRawPtr]"
  //      }))
  //      else
  //      \(indentCode(indent: options.indent, {
  //        "\(constructNew)"
  //      }))
  //      end
  //      """
  //    }))
  //    end
  //    """
  //  }

  //  // TODO: optional namedArguments initializers (option)
  //  var argCounts: Set<Int> = Set()
  //  for function in initializers {
  //    let count = function.arguments.count
  //    if argCounts.contains(count) {
  //      throw GenerationError("Cannot specify multiple initializers with the same amount of parameters", .ruby)
  //    }
  //    argCounts.insert(count)
  //  }

  //  return """
  //  def initialize *args
  //  \(try indentCode(indent: options.indent, {
  //    if hasDeinit {
  //      defDeinit
  //    }
  //    """
  //    if args.count == 1 && args.first.is_a?(Hash) && args.first.size == 1 && args.first[:fromRawPtr] != nil
  //    \(indentCode(indent: options.indent, {
  //      "@ptr = args.first[:fromRawPtr]"
  //    }))
  //    \(try initializers.map { fn in
  //      //let fnName = "\(ffiModuleName).\(fn.ffiName!)"
  //      //let fnCall = "\(fnName)\((0..<fn.arguments.count).map { "args[\($0)]" }.joined(separator: ", "))"
  //      let fnCall = try fn.generateRubyInitializerSetPtr(selfType: selfType, ffiModuleName: ffiModuleName)
  //      return """
  //      else if args.size == \(fn.arguments.count)
  //      \(options.indent)\(fnCall)
  //      """
  //    })
  //    else
  //    \(options.indent)raise "Unexpected amount of arguments #{args.size} for type \(initializers[0].attachedTo!.bindingName!) (expected \(initializers.map { String($0.arguments.count) }.sorted().joined(separator: ", ")))"
  //    end
  //    """
  //  }))
  //  end
  //  """
  //}



  func generateRubyFFICode(
    options: GenerationOptions,
    in lib: OctoLibrary
  ) throws -> String {
    """
    attach_function :\(self.ffiName!), [\(try self.arguments.map { arg in
      try arg.type.rubyFFIType()
    }.joined(separator: ", "))], \(try self.returnType.rubyFFIType())
    """
  }

  private func rubyBindingCodeData(
    _ ffiModuleName: String,
    parseSelfParameter: Bool = true
  ) -> (String, [String], [String]) {
    let fnName = "\(ffiModuleName).\(self.rubyFFIName)"

    var argNames = self.arguments.enumerated().map { (i, arg) in arg.bindingName ?? "_arg_\(i)" }
    if parseSelfParameter {
      if let selfArgPos = self.selfArgumentIndex {
        argNames[selfArgPos] = "self"
      }
    }

    let passedArgs = zip(self.arguments, argNames).map { (arg, argName) in
      arg.type.rubyToC(argName)
    }

    if parseSelfParameter {
      if let selfArgPos = self.selfArgumentIndex {
        argNames.remove(at: selfArgPos)
      }
    }

    return (fnName, argNames, passedArgs)
  }

  func generateRubyDeinitializerCode(
    options: GenerationOptions,
    in lib: OctoLibrary,
    ffiModuleName: String
  ) throws -> String {
    let (fnName, _, _) = self.rubyBindingCodeData(ffiModuleName)
    if self.arguments.count > 1 {
      throw GenerationError("Deinitializer only supports 1 parameter of type `Self`", .ruby, origin: self.origin)
    }

    guard self.hasSelfArgument else {
      throw GenerationError("Deinitializer requires a self parameter", .ruby, origin: self.origin)
    }
    return """
    DESTROY = lambda { |object_id|
    \(indentCode(indent: options.indent, {
      "\(fnName)(ObjectSpace._id2ref(object_id).\(rubyPtrName))"
    }))
    }
    """
  }

  func generateRubyMethodCode(
    options: GenerationOptions,
    in lib: OctoLibrary,
    ffiModuleName: String
  ) throws -> String {
    return try self._generateRubyFunctionCode(options: options, in: lib, ffiModuleName: ffiModuleName, isStatic: false)
  }

  func generateRubyStaticMethodCode(
    options: GenerationOptions,
    in lib: OctoLibrary,
    ffiModuleName: String
  ) throws -> String {
    return try self._generateRubyFunctionCode(options: options, in: lib, ffiModuleName: ffiModuleName, isStatic: true)
  }

  private func _generateRubyFunctionCode(
    options: GenerationOptions,
    in lib: OctoLibrary,
    ffiModuleName: String,
    isStatic: Bool
  ) throws -> String {
    let (fnName, argNames, passedArgs) = self.rubyBindingCodeData(ffiModuleName, parseSelfParameter: !isStatic)

    if self.hasUserTypeArgument || self.returnType.isUserType {
      return """
      def \(isStatic ? "self." : "")\(self.rubyName) \(argNames.joined(separator: ", "))
      \(indentCode(indent: options.indent, {
        self.returnType.cToRuby("\(fnName)(\(passedArgs.joined(separator: ", ")))")
      }))
      end
      """
    } else {
      return """
      define\(isStatic ? "_singleton" : "")_method :\(self.rubyName), \(ffiModuleName).instance_method(:\(self.ffiName!))
      """
    }
  }

  func generateRubyBindingCode(
    options: GenerationOptions,
    in lib: OctoLibrary,
    ffiModuleName: String
  ) throws -> String {
    switch (self.kind) {
      case .initializer: // Only one initializer
        throw GenerationError("Direct initializer generation is not supported, use `generateRubyBindingInitializersCode` (please open a bug report)", .ruby, origin: self.origin)
      case .deinitializer:
        return try generateRubyDeinitializerCode(options: options, in: lib, ffiModuleName: ffiModuleName)
      case .method:
        return try generateRubyMethodCode(options: options, in: lib, ffiModuleName: ffiModuleName)
      case .staticMethod: fallthrough
      case .function:
        return try generateRubyStaticMethodCode(options: options, in: lib, ffiModuleName: ffiModuleName)
    }
  }

  var rubyName: String {
    self.bindingName!
  }

  var rubyFFIName: String {
    self.ffiName!
  }
}


extension OctoArgument {
  var rubyName: String? {
    self.bindingName
  }
}
