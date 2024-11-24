import OctoIntermediate
import OctoIO

extension OctoEnum: RubyCodeGenerator {
  func generateRubyFFICode(options: GenerationOptions, in lib: OctoLibrary) throws -> String {
    """
    \(self.rubyFFIName) = enum \(self.cases.map { enumCase in
      if let enumValue = enumCase.value {
        return ":\(enumCase.bindingName!), \(enumValue.literalValue)"
      } else {
        return ":\(enumCase.bindingName!)"
      }
    }.joined(separator: ",\n\(String(repeating: " ", count: "enum ".count))"))
    """
  }

  func generateRubyBindingCode(options: GenerationOptions, in lib: OctoLibrary, ffiModuleName: String) throws -> String {
    if self.deinitializer != nil {
      octoLogger.warning("Automatic deinitializers on enums are not currently supported for ruby. A static method will be generated which has to be called manually")
    }

    return """
    module \(self.rubyName)
    \(try indentCode(indent: options.indent, {
      """
      def self.__cToRuby(enumValue)
      \(indentCode(indent: options.indent, {
        """
        if enumValue.is_a? :symbol
        \(options.indent)return enumValue
        else
        \(indentCode(indent: options.indent, {
          """
          case enumValue
          \(self.cases.map { enumCase in
            "when \(enumCase.value!.literalValue) then return :\(enumCase.bindingName!)"
          }.joined(separator: "\n"))
          end
          """
        }))
        end
        """
      }))
      end
      """

      for initializer in self.initializers {
        try initializer.generateRubyStaticMethodCode(options: options, in: lib, ffiModuleName: ffiModuleName)
      }

      for method in self.methods {
        try method.generateRubyStaticMethodCode(options: options, in: lib, ffiModuleName: ffiModuleName)
      }

      for staticMethod in self.staticMethods {
        try staticMethod.generateRubyStaticMethodCode(options: options, in: lib, ffiModuleName: ffiModuleName)
      }

      if let deinitializer = self.deinitializer {
        try deinitializer.generateRubyStaticMethodCode(options: options, in: lib, ffiModuleName: ffiModuleName)
      }
    }))
    end
    """
  }

  func rubyToC(_ param: String) -> String {
    param
  }

  var rubyFFIName: String {
    rubyConstantName(of: self.ffiName!)
  }

  var rubyName: String {
    rubyConstantName(of: self.bindingName!)
  }
}
