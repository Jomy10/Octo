import OctoIntermediate
import OctoGenerateShared
import OctoIO

func rubyConstantName(of name: some StringProtocol) -> String {
  if name.first!.isLetter {
    if name.first!.isUppercase {
      return String(name)
    } else {
      return String(name[name.startIndex].uppercased() + name[name.index(name.startIndex, offsetBy: 1)...])
    }
  } else {
    return rubyConstantName(of: name[name.startIndex...])
  }
}

let rubyPtrName = "__ptr"

extension OctoLibrary {
  func rubyGenerate(options: GenerationOptions) throws -> RubyCode {
    let moduleName = rubyConstantName(of: options.moduleName)
    let ffiModuleName = "\(moduleName)_FFI"

    let genObjs = self.objects
      .filter { obj in obj is RubyCodeGenerator }
      .map { obj in obj as! RubyCodeGenerator }

    let code = """
    require 'ffi'

    module \(ffiModuleName)
    \(indentCode(indent: options.indent, {
      "extend FFI::Library"
      "ffi_lib \(options.libs.map { "'\($0)'" }.joined(separator: ", "))"
    }))
    \(options.indent)
    \(try indentCode(indent: options.indent, {
      for object in genObjs {
        try object.generateRubyFFICode(options: options, in: self)
      }
    }))
    end

    module \(moduleName)
    \(try indentCode(indent: options.indent, {
      for object in (genObjs.filter { obj in
        if let fnObj = obj as? OctoFunction {
          return fnObj.kind == .function
        } else {
          return true
        }
      }) {
        try object.generateRubyBindingCode(options: options, in: self, ffiModuleName: ffiModuleName)
      }

      self.typedefs.map { (name, type) in
        switch (type.kind) {
          case .Record(let record): return "\(rubyConstantName(of: name)) = \(record.rubyName)"
          case .Enum(let e): return "\(rubyConstantName(of: name)) = \(e.rubyName)"
          case .Pointer(to: let val):
            switch (val.kind) {
              case .Record(let record): return "\(rubyConstantName(of: name)) = \(record.rubyName)"
              case .Enum(let e): return "\(rubyConstantName(of: name)) = \(e.rubyName)"
              default: return ""
            }
          default: return ""
        }
      }.joined(separator: "\n")
    }))
    end
    """

    return RubyCode(code: code)
  }
}
