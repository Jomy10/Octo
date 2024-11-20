import OctoIO

extension OctoFunction {
  func rubyGenerateFFI(in lib: OctoLibrary, options: GenerationOptions) -> String {
    """
    attach_function \(rubyIdent(ident: self.rubyFFIName)), [\(self.params.map { paramId in
      lib.getParameter(id: paramId)!.type.rubyTypeDef!
    }.joined(separator: ", "))], \(self.returnType.rubyTypeDef!)
    """
  }

  func rubyGenerateModule(in lib: OctoLibrary, options: GenerationOptions, ffiModuleName: String) throws -> String {
    var aParameters = self.rubyParameterNames(in: lib)
    if self.functionType == .`init` {
      aParameters = (0..<aParameters.count).map { i in "args[\(i)]"}
    }
    var aInputParameters = try self.rubyInputParameters(fromParameterNames: aParameters, ffiModuleName: ffiModuleName, in: lib)

    if let selfParameter = self.selfParameter(in: lib) {
      aParameters.remove(at: selfParameter)
      aInputParameters[selfParameter] = "@ptr.\(rubyInnerPtrName)"
    } else {
      if self.functionType == .`deinit` {
        throw GenerationError("Deinitializer should contain a self parameter", .ruby, self.origin)
      }
    }

    let parameters = aParameters.joined(separator: ", ")
    let inputParameters = aInputParameters.joined(separator: ", ")

    var fnCall = "\(ffiModuleName).\(self.rubyFFIName)(\(inputParameters))"

    if self.functionType != .`init` {
      // convert return type to ruby type
      switch (returnType.kind) {
      case .UserDefined(name: let name, id: let id):
        guard let userTypeId = (id == nil ? nil : lib.getUserType(lid: id!)) ?? lib.getUserType(name: name) else {
          if lib.getTypedef(name: name) == nil {
            throw GenerationError("Cannot find user type \(name)", .ruby, self.origin)
          }
          break // it's a regular C type that is typedef'd
        }
        switch (lib.getUserType(id: userTypeId)!.inner) {
        case .record(let record):
          fnCall = "\(record.bindingName).new(fromRawPtr: \(fnCall))"
        case .`enum`:
          break
          //fnCall = "\(enu.bindingName).new(fromRawPtr: \(fnCall))"
        }
      case .ConstantArray:
        octoLogger.warning("unimplemented")
      case .Pointer(to: let type):
        switch (type.kind) {
        case .UserDefined(name: let name, id: let id):
          let userTypeId = (id == nil ? nil : lib.getUserType(lid: id!)) ?? lib.getUserType(name: name)!
          switch (lib.getUserType(id: userTypeId)!.inner) {
          case .record(let record):
            fnCall = "\(record.bindingName).new(fromRawPtr: \(fnCall))"
          case .`enum`:
            break
            //fnCall = "\(enu.bindingName).new(fromRawPtr: \(fnCall))"
          }
        case .ConstantArray:
          octoLogger.warning("unimplemented")
        default:
          break
        }
      default:
        break
      }
    }

    switch (self.functionType) {
    case .function: fallthrough
    case .staticMethod:
      if self.containsUserType {
        return """
        define_singleton_method \(rubyIdent(ident: self.rubyName)), \(ffiModuleName).instance_method(\(rubyIdent(ident: self.rubyFFIName)))
        """
      } else {
        return """
        def self.\(self.rubyName) \(parameters)
        \(options.indent)\(fnCall)
        end
        """
      }
    case .method:
      if self.containsUserType {
        return """
        define_singleton_method \(rubyIdent(ident: self.rubyName)), \(ffiModuleName).instance_method(\(rubyIdent(ident: self.rubyFFIName)))
        """
      } else {
        return """
        def \(self.rubyName) \(parameters)
        \(options.indent)\(fnCall)
        end
        """
      }
    case .`deinit`:
      if self.params.count != 1 {
        octoLogger.fatal("Deinitializer can only contain one parameter")
      }
      return """
      def self.release ptr
      \(options.indent)\(ffiModuleName).\(self.rubyFFIName) ptr
      end
      """
    case .`init`:
      return """
      def initialize *args
      \(indentCode(indent: options.indent, {
        """
        if args.is_a? Hash
        \(options.indent)@ptr = args[:fromRawPtr]
        else
        \(options.indent)@ptr = \(fnCall)
        end
        """
      }))
      end
      """
    }
  }

  var rubyFFIName: String {
    self.name
  }

  var rubyName: String {
    self.bindingName
  }

  func rubyParameterNames(in lib: OctoLibrary) -> [String] {
    self.params.enumerated().map { (i, paramId) in
      lib.getParameter(id: paramId)!.name ?? "_parameter_\(i)"
    }
  }

  func rubyInputParameters(fromParameterNames parameterNames: [String], ffiModuleName: String, in lib: OctoLibrary) throws -> [String] {
    guard case .Function(callingConv: _, args: let argTypes, result: _) = self.type.kind else {
      octoLogger.fatal("unreachable")
    }

    return try zip(
      parameterNames,
      argTypes
    ).map { (parameterName, argType) in
      return try argType.rubyConvertParameterToFFI(ofName: parameterName, ffiModuleName: ffiModuleName, in: lib)
    }
  }
}

extension OctoType {
  func rubyConvertParameterToFFI(ofName parameterName: String, ffiModuleName: String, in lib: OctoLibrary) throws -> String {
    switch (self.kind) {
    case .UserDefined(name: let name, id: let id):
      guard let userTypeId = (id == nil ? nil : lib.getUserType(lid: id!)) ?? lib.getUserType(name: name) else {
        if lib.getTypedef(name: name) == nil {
          throw GenerationError("Cannot find user type \(name)", .ruby)
        }
        // it's a regular C type that is typedef'd
        return parameterName
      }

      switch (lib.getUserType(id: userTypeId)!.inner) {
      case .record:
        return "\(parameterName).\(rubyInnerPtrName)"
      case .`enum`(let enu):
        return "(\(parameterName).is_a?(Symbol) ? \(ffiModuleName)::\(enu.rubyFFIName)[\(parameterName)] : \(parameterName))"
      }
    case .Pointer(to: let pointeeType):
      if case .UserDefined = (pointeeType.kind) {
        return try pointeeType.rubyConvertParameterToFFI(ofName: parameterName, ffiModuleName: ffiModuleName, in: lib)
      } else {
        return parameterName
      }
    default:
      return parameterName
    }
  }
}
