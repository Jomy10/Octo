import Foundation
import OctoIO

extension OctoRecord {
  func rubyGenerateFFI(in lib: OctoLibrary, options: GenerationOptions) -> String {
    let ffiClassName: String
    switch (self.type) {
      case .`struct`: ffiClassName = "FFI::Struct"
      case .`union`: ffiClassName = "FFI::Union"
    }

    return """
    class \(self.rubyFFIName) < \(ffiClassName)
    \(options.indent)layout \(self.fields.map { fieldId in
      lib.getField(id: fieldId)!
    }.map { field in
      "\(rubyIdent(ident: field.name)), \(field.type.rubyTypeDef!)"
    }.joined(separator: ",\n\(options.indent)\(String(repeating: " ", count: "layout ".count))"))
    end
    """
  }

  func rubyGenerateModule(in lib: OctoLibrary, options: GenerationOptions, ffiModuleName: String) throws -> String {
    if self.initializers.count > 1 {
      octoLogger.fatal("unimplemented")
    }

    let genModCodeForFn = { (fnId: UUID) -> String in
      try lib.getFunction(id: fnId)!.rubyGenerateModule(in: lib, options: options, ffiModuleName: ffiModuleName)
    }

    return """
    class \(self.rubyName)\(self.hasDeinitializer ? " < FFI::ManagedStruct" : "")
    \(try indentCode(indent: options.indent, {
      for fnId in self.initializers {
        try genModCodeForFn(fnId)
      }

      """
      def \(rubyInnerPtrName)
      \(options.indent)@ptr
      end
      """

      for fieldId in self.fields {
        let field = lib.getField(id: fieldId)!
        if field.visible {
          """
          def \(field.name)
          \(options.indent)@ptr[:\(field.name)]
          end
          """

          if field.type.isMutable {
            """
            def \(field.name)=(newValue)
            \(options.indent)@ptr[:\(field.name)] = newValue
            end
            """
          }
        }
      }

      for fnId in self.methods {
        try genModCodeForFn(fnId)
      }

      for fnId in self.staticMethods {
        try genModCodeForFn(fnId)
      }

      if let fnId = self.deinitializer {
        try genModCodeForFn(fnId)
      }
    }))
    end
    """
  }

  var rubyFFIName: String {
    rubyConstantName(of: self.name)
  }

  var rubyName: String {
    rubyConstantName(of: self.bindingName)
  }
}
