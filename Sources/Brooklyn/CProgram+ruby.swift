import Clang

extension CProgram {
  func convertRuby(
    _ headerIncluded: ((String) throws -> Bool)?,
    options: ConversionOptions
  ) throws -> String {
    var fileIncluded: [CXFile:Bool] = [:]
    let isFileIncluded: (CXFile) throws -> Bool = { file in
      guard let isHeaderIncluded = headerIncluded else {
        return true
      }
      if let included = fileIncluded[file] {
        return included
      } else {
        let fileName = file.fileName
        let included = try isHeaderIncluded(fileName)
        fileIncluded[file] = included
        return included
      }
    }

    var userTypeCode: [String] = []
    for (_, userType) in self.userTypes {
      let headerIncluded = try isFileIncluded(userType.origin.expansionLocation.file)
      if !headerIncluded { continue }

      switch (userType) {
        case .struct(let record):
          userTypeCode.append(Self.ruby_parseRecord(record: record, type: .struct, options: options))
        case .union(let record):
          userTypeCode.append(Self.ruby_parseRecord(record: record, type: .union, options: options))
        case .enum(let cenum):
          let code = """
          \(cenum.name) = enum \(
              cenum.constants
                .map { (_, constant) in Self.rubyEnumConstant(constant) }
                .joined(separator: ",\n\(options.indent)")
            )
          """
          userTypeCode.append(code)
      }
    }

    var typedefCode: [String] = []
    for (_, typedef) in self.typedefs {
      let headerIncluded = try isFileIncluded(typedef.origin.expansionLocation.file)
      if !headerIncluded { continue }

      guard let referredToTypeName = typedef.refersTo.rubyType else {
        fatalError("Unhandled type in ruby \(typedef.refersTo)")
      }
      typedefCode.append("\(typedef.name) = \(referredToTypeName)")
    }

    var globalVariableCode: [String] = []
    for (_, variable) in self.globalVariables {
      let headerIncluded = try isFileIncluded(variable.origin.expansionLocation.file)
      if !headerIncluded { continue }

      globalVariableCode.append("attach_variable \(Self.rubyIdent(ident: variable.name)), \(variable.type.rubyType!)")
    }

    var functionCode: [String] = []
    for (_, function) in self.functions {
      let headerIncluded = try isFileIncluded(function.origin.expansionLocation.file)
      if !headerIncluded { continue }

      let functionName = Self.rubyIdent(ident: function.name)
      let types: [String] = function.parameters.map { $0.type.rubyType! }
      let returnType = function.returnType.rubyType
      functionCode.append("attach_function \(functionName), [\(types.joined(separator: ", "))], \(returnType)")
    }

    return """
    require 'ffi'
    module \(options.libraryName)_FFI
    \(options.indent)extend FFI::Library
    \(options.indent)ffi_lib \(options.ffiLibraryName!)
    \(options.indent)
    \(options.indent)\(Self.rubyFormatModuleCode(userTypeCode, options: options))
    \(options.indent)
    \(options.indent)\(Self.rubyFormatModuleCode(typedefCode, options: options))
    \(options.indent)
    \(options.indent)\(Self.rubyFormatModuleCode(globalVariableCode, options: options))
    \(options.indent)
    \(options.indent)\(Self.rubyFormatModuleCode(functionCode, options: options))
    end
    """
  }

  static func rubyFormatModuleCode(_ moduleCode: [String], options: ConversionOptions) -> String {
    return moduleCode
      .map { $0.split(separator: "\n").joined(separator:  "\n\(options.indent)") }
      .joined(separator: "\n\(options.indent)\n\(options.indent)")
  }

  static func rubyIdent(ident: String) -> String {
    return ":\(ident)"
  }

  static func rubyEnumConstant(_ c: CEnumConstant) -> String {
    "\(c.name), \(c.value)"
  }

  enum RecordType {
    case `struct`
    case union

    var rubyName: String {
      switch (self) {
        case .struct: return "FFI::Struct"
        case .union: return "FFI::Union"
      }
    }
  }

  static func ruby_parseRecord(record: CRecord, type: RecordType, options: ConversionOptions) -> String {
    var layout = ""
    if record.fields.count > 0 {
      layout = """
      layout \(
        record.fields
          .map { field in "\(Self.rubyIdent(ident: field.name)), \(field.type.rubyType!)" }
          .joined(separator: ",\n\(options.indent)\(String(repeating: " ", count: "layout ".count))")
      )
      """
    }

    return """
    class \(record.name) < \(type.rubyName)
    \(options.indent)\(layout)
    end
    """
  }
}

fileprivate extension CType {
  /// Returns nil if not supported
  var rubyType: String? {
    switch (self.kind) {
      case .Invalid: return nil
      case .Void: return ":void"
      case .Bool: return ":bool"
      case .Char_U: fallthrough
      case .UChar: return ":uchar"
      case .Char_S: fallthrough
      case .SChar: return ":char"
      case .WChar:
        switch (self.size) {
          case 8: return ":char"
          case 16: return "int16"
          case 32: return "int32"
          case 64: return "int64"
          default: return nil
        }
      case .Char16: return ":short"
      case .Char32: return ":int32"
      case .UShort: return ":ushort"
      case .UInt: return ":uint"
      case .ULong: return ":ulong"
      case .ULongLong: return ":ulong_long"
      case .UInt128: return nil
      case .Short: return ":short"
      case .Int: return ":int"
      case .Long: return ":long"
      case .LongLong: return ":long_long"
      case .Int128: return nil
      case .Float: return ":float"
      case .Double: return ":double"
      case .LongDouble: return nil
      case .Pointer(to: let pointeeType): fallthrough
      case .LValueReference(to: let pointeeType): fallthrough
      case .RValueReference(to: let pointeeType):
        switch (pointeeType.kind) {
          case .Elaborated(name: let typeName, prefix: _):
            return "\(typeName).ptr"
          case .UChar: fallthrough
          case .Char_U: return ":strptr"
          default: return ":pointer"
        }
      case .FunctionProto(callingConv: _, args: _, result: _): fallthrough
      case .FunctionNoProto(callingConv: _, args: _, result: _):
        return ":pointer"
      case .ConstantArray: return ":pointer"
      case .Elaborated(name: let name, prefix: _): return "\(name)"
    }
  }
}
