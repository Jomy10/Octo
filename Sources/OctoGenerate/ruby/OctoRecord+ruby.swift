import OctoIntermediate

extension OctoRecord: RubyCodeGenerator {
  func generateRubyFFICode(options: GenerationOptions, in lib: OctoLibrary) throws -> String {
    let ffiClassInherits: String
    switch (self.type) {
      case .`struct`: ffiClassInherits = "FFI::Struct"
      case .`union`: ffiClassInherits = "FFI::Union"
    }

    return """
    class \(rubyConstantName(of: self.ffiName!)) < \(ffiClassInherits)
    \(try indentCode(indent: options.indent, {
      """
      layout \(try self.fields.map { field in
        ":\(field.ffiName!), \(try field.type.rubyFFIType())"
      }.joined(separator: ",\n\(String(repeating: " ", count: "layout ".count))"))
      """
    }))
    end
    """
  }

  func generateRubyBindingCode(options: GenerationOptions, in lib: OctoLibrary, ffiModuleName: String) throws -> String {
    return """
    class \(rubyConstantName(of: self.bindingName!))
    \(try indentCode(indent: options.indent, {
      """
      def \(rubyPtrName)
        @ptr
      end
      """

      try OctoFunction.generateRubyBindingInitializersCode(for: self, hasDeinit: self.deinitializer != nil, options: options, in: lib, ffiModuleName: ffiModuleName)

      for field in self.fields {
        """
        def \(field.bindingName!)
          \(field.type.cToRuby("@ptr[:\(field.ffiName!)]"))
        end

        def \(field.bindingName!)=newValue
          @ptr[:\(field.ffiName!)] = \(field.type.rubyToC("newValue"))
        end
        """
      }

      for method in self.methods {
        try method.generateRubyBindingCode(options: options, in: lib, ffiModuleName: ffiModuleName)
      }

      for staticMethod in self.staticMethods {
        try staticMethod.generateRubyBindingCode(options: options, in: lib, ffiModuleName: ffiModuleName)
      }

      if let deinitializer = self.deinitializer {
        try deinitializer.generateRubyBindingCode(options: options, in: lib, ffiModuleName: ffiModuleName)
      }
    }))
    end
    """
  }

  var rubyName: String {
    rubyConstantName(of: self.bindingName!)
  }

  var rubyFFIName: String {
    rubyConstantName(of: self.ffiName!)
  }

  func rubyToC(_ param: String) -> String {
    "\(param).\(rubyPtrName)"
  }
}
