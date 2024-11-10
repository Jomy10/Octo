import Foundation

struct RubyCode: GeneratedCode {
  let code: String

  func write(to url: URL) throws {
    try self.code.write(to: url, atomically: true, encoding: .utf8)
  }

  var description: String {
    return code
  }
}

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

func rubySafeVariable(_ name: String) -> String {
  switch (name) {
    case "next": return "_next"
    case "case": return "_case"
    default: return name
  }
}

func rubyIdent(ident: String) -> String {
  ":\(ident)"
}

let rubyInnerPtrName = "__Octo_Ptr"

extension OctoLibrary {
  func rubyGenerate(options: GenerationOptions) -> RubyCode {
    let moduleName = rubyConstantName(of: self.name)
    let ffiModuleName = "\(moduleName)_FFI"

    let code = """
    require 'ffi'

    module \(ffiModuleName)
      include FFI::Library
      lib_name \(options.libs.map { lib in "'\(lib)'" }.joined(separator: ", "))

    \(indentCode(indent: options.indent, {
      for (_, userType) in self.userTypes {
        userType.rubyGenerateFFI(in: self, options: options)
      }

      for (_, typedef) in self.typedefs {
        typedef.rubyGenerateFFI(in: self, options: options)
      }

      for (_, function) in self.functions {
        function.rubyGenerateFFI(in: self, options: options)
      }
    }))
    end

    module \(moduleName)
    \(indentCode(indent: options.indent, {
      for (_, userType) in self.userTypes {
        userType.rubyGenerateModule(in: self, options: options, ffiModuleName: ffiModuleName)
      }

      for (_, typedef) in self.typedefs {
        typedef.rubyGenerateModule(in: self, options: options, ffiModuleName: ffiModuleName)
      }

      for (_, function) in self.functions.filter({ (fnId: UUID, _) in !self.getFunction(id: fnId)!.isAttached }) {
        function.rubyGenerateModule(in: self, options: options, ffiModuleName: ffiModuleName)
      }
    }))
    end
    """

    return RubyCode(code: code)
  }
}
