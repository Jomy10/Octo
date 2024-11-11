extension OctoFunction {
  func rubyGenerateFFI(in lib: OctoLibrary, options: GenerationOptions) -> String {
    """
    attach_function \(rubyIdent(ident: self.rubyFFIName)), [\(self.params.map { paramId in
      lib.getParameter(id: paramId)!.type.rubyTypeDef!
    }.joined(separator: ", "))], \(self.returnType.rubyTypeDef!)
    """
  }

  func rubyGenerateModule(in lib: OctoLibrary, options: GenerationOptions, ffiModuleName: String) -> String {
    var aParameters = self.rubyParameterNames(in: lib)
    if self.functionType == .`init` {
      aParameters = (0..<aParameters.count).map { i in "args[\(i)]"}
    }
    var aInputParameters = self.rubyInputParameters(fromParameterNames: aParameters, ffiModuleName: ffiModuleName, in: lib)

    if let selfParameter = self.selfParameter(in: lib) {
      aParameters.remove(at: selfParameter)
      aInputParameters[selfParameter] = "@ptr.\(rubyInnerPtrName)"
    } else {
      if self.functionType == .`deinit` {
        fatalError("[\(self.origin)] ERROR: Deinitializer should contain a self parameter")
      }
    }

    let parameters = aParameters.joined(separator: ", ")
    let inputParameters = aInputParameters.joined(separator: ", ")

    var fnCall = "\(ffiModuleName).\(self.rubyFFIName)(\(inputParameters))"

    if self.functionType != .`init` {
      // convert return type to ruby type
      switch (returnType.kind) {
      case .UserDefined(name: let name):
        let userTypeId = lib.getUserType(name: name)!
        switch (lib.getUserType(id: userTypeId)!.inner) {
        case .record(let record):
          fnCall = "\(record.bindingName).new(fromRawPtr: \(fnCall))"
        case .`enum`:
          break
          //fnCall = "\(enu.bindingName).new(fromRawPtr: \(fnCall))"
        }
      case .ConstantArray:
        print("[WARNING] unimplemented")
      case .Pointer(to: let type):
        switch (type.kind) {
        case .UserDefined(name: let name):
          let userTypeId = lib.getUserType(name: name)!
          switch (lib.getUserType(id: userTypeId)!.inner) {
          case .record(let record):
            fnCall = "\(record.bindingName).new(fromRawPtr: \(fnCall))"
          case .`enum`:
            break
            //fnCall = "\(enu.bindingName).new(fromRawPtr: \(fnCall))"
          }
        case .ConstantArray:
          print("[WARNING] unimplemented")
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
        fatalError("Deinitializer can only contain one parameter")
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

  func rubyInputParameters(fromParameterNames parameterNames: [String], ffiModuleName: String, in lib: OctoLibrary) -> [String] {
    guard case .Function(callingConv: _, args: let argTypes, result: _) = self.type.kind else {
      fatalError("unreachable")
    }

    return zip(
      parameterNames,
      argTypes
    ).map { (parameterName, argType) in
      return argType.rubyConvertParameterToFFI(ofName: parameterName, ffiModuleName: ffiModuleName, in: lib)
    }
  }
}

extension OctoType {
  func rubyConvertParameterToFFI(ofName parameterName: String, ffiModuleName: String, in lib: OctoLibrary) -> String {
    switch (self.kind) {
    case .UserDefined(name: let name):
      let userTypeId = lib.getUserType(name: name)!
      switch (lib.getUserType(id: userTypeId)!.inner) {
      case .record:
        return "\(parameterName).\(rubyInnerPtrName)"
      case .`enum`(let enu):
        return "(\(parameterName).is_a?(Symbol) ? \(ffiModuleName)::\(enu.rubyFFIName)[\(parameterName)] : \(parameterName))"
      }
    case .Pointer(to: let pointeeType):
      if case .UserDefined = (pointeeType.kind) {
        return pointeeType.rubyConvertParameterToFFI(ofName: parameterName, ffiModuleName: ffiModuleName, in: lib)
      } else {
        return parameterName
      }
    default:
      return parameterName
    }
  }
}
