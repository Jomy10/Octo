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

    let ffiEqBinding = self.cases.allSatisfy({ $0.ffiName == $0.rubyName })

    return """
    module \(self.rubyName)
    \(try indentCode(indent: options.indent, {
      """
      def self.__cToRuby(enumValue)
      \(indentCode(indent: options.indent, {
        """
        if enumValue.is_a? Symbol
        \(indentCode(indent: options.indent, {
          if ffiEqBinding {
            "return enumValue"
          } else {
            """
            case enumValue
            \(self.cases.map { enumCase in
              "when :\(enumCase.ffiName!) then return :\(enumCase.rubyName)"
            }.joined(separator: "\n"))
            else raise "#{enumValue} is not a valid enum value of \(self.rubyName)"
            end
            """
          }
        }))
        \(options.indent)return enumValue
        else
        \(indentCode(indent: options.indent, {
          """
          case enumValue
          \(self.cases.map { enumCase in
            "when \(enumCase.value!.literalValue) then return :\(enumCase.rubyName)"
          }.joined(separator: "\n"))
          else raise "Unexpectedly got #{enumValue} for enum \(self.bindingName!)"
          end
          """
        }))
        end
        """
      }))
      end

      def self.__rubyToC(enumValue)
      \(indentCode(indent: options.indent, {
        """
        if enumValue.is_a? Integer
        \(options.indent)return enumValue
        else
        \(indentCode(indent: options.indent, {
          if ffiEqBinding {
            "return enumValue"
          } else {
            """
            case enumValue
            \(self.cases.map { enumCase in
              "when :\(enumCase.rubyName) then return \(enumCase.value!.literalValue)"
            }.joined(separator: "\n"))
            else raise "#{enumValue} is not a valid enum value of \(self.rubyName)"
            end
            """
          }
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

  func cToRuby(_ param: String) -> String {
    "\(self.rubyName).__cToRuby(\(param))"
  }

  func rubyToC(_ param: String) -> String {
    "\(self.rubyName).__rubyToC(\(param))"
  }

  var rubyFFIName: String {
    rubyConstantName(of: self.ffiName!)
  }

  var rubyName: String {
    rubyConstantName(of: self.bindingName!)
  }
}

extension OctoEnumCase {
  var rubyName: String {
    self.bindingName == self.ffiName ? self.strippedName! : self.bindingName!
  }
}
