import OctoIntermediate
import OctoGenerateShared

struct RubyInitializerBuilder {
  static func build(
    for record: OctoRecord,
    //in lib: OctoLibrary,
    options: GenerationOptions,
    ffiModuleName: String
  ) throws -> String {
    // Check initializers arguments counts
    var argCounts: Set<Int> = Set()
    for function in record.initializers {
      let count = function.arguments.count
      if argCounts.contains(count) {
        throw GenerationError("Cannot specify multiple initializers with the same amount of parameters", .ruby, origin: function.origin)
      }
      argCounts.insert(count)
    }

    switch (record.type) {
      case .`struct`: fallthrough
      case .taggedUnion:
        return try Self.buildStructInitializer(
          for: record,
          //in: lib,
          options: options,
          ffiModuleName: ffiModuleName
        )
      case .union:
        return try Self.buildUnionInitializer(
          for: record,
          //in: lib,
          options: options,
          ffiModuleName: ffiModuleName
        )
    }
  }

  private static func buildStructInitializer(
    for record: OctoRecord,
    //in lib: OctoLibrary,
    options: GenerationOptions,
    ffiModuleName: String
  ) throws -> String {
    """
    def initialize *args
    \(try indentCode(indent: options.indent, {
      Self.assignDeinitializer(for: record)

      try Self.buildBody_arrayArgs(for: record, options: options, ffiModuleName: ffiModuleName, withMemberwiseInitializer: Self.buildStructBody_memberWiseInitializer)
    }))
    end
    """
  }

  private static func buildUnionInitializer(
    for record: OctoRecord,
    //in lib: OctoLibrary,
    options: GenerationOptions,
    ffiModuleName: String
  ) throws -> String {
    """
    def initialize *args
    \(try indentCode(indent: options.indent, {
      Self.assignDeinitializer(for: record)

      try Self.buildBody_arrayArgs(for: record, options: options, ffiModuleName: ffiModuleName, withMemberwiseInitializer: Self.buildUnionBody_memberWiseInitializer)
    }))
    end
    """
  }

  private static func assignDeinitializer(for record: OctoRecord) -> String {
    if record.deinitializer != nil {
      return "ObjectSpace.define_finalizer(self, DESTROY)"
    } else {
      return ""
    }
  }

  private static func buildBody_rawPtrWithArrayArgs(
    for record: OctoRecord,
    options: GenerationOptions
  ) -> String {
    """
    if args.size == 1 && args.first.is_a?(Hash) && args.first.size == 1 && args.first[:fromRawPtr] != nil
    \(options.indent)@ptr = args.first[:fromRawPtr]
    """
  }

  private static func buildStructBody_memberWiseInitializer(
    _ record: OctoRecord,
    _ options: GenerationOptions,
    _ ffiModuleName: String
  ) -> String {
    """
    elsif args.size == 1 && args.first.is_a?(Hash) && args.first.size == \(record.fields.count)
    \(indentCode(indent: options.indent, {
      "@ptr = \(ffiModuleName)::\(record.rubyFFIName).new"
      for field in record.fields {
        "@ptr[:\(field.ffiName!)] = \(field.type.rubyToC("args.first[:\(field.bindingName!)]"))"
      }
    }))
    """
  }

  private static func buildUnionBody_memberWiseInitializer(
    _ record: OctoRecord,
    _ options: GenerationOptions,
    _ ffiModuleName: String
  ) -> String {
    """
    elsif args.size == 1 && args.first.is_a?(Hash) && args.first.size == 1
    \(indentCode(indent: options.indent, {
      "@ptr = \(ffiModuleName)::\(record.rubyFFIName).new"

      """
      case args.first[0]
      \(record.fields.map { field in
        "when :\(field.bindingName!) then @ptr[:\(field.ffiName!)] = \(field.type.rubyToC("args.first[:\(field.bindingName!)]"))"
      }.joined(separator: "\n "))
      end
      """
    }))
    """
  }

  private static func buildBody_rawPtrWithHashArgs(
    for record: OctoRecord,
    options: GenerationOptions
  ) -> String {
    """
    if args[:fromRawPtr] != nil && args.size == 1
    \(options.indent)@ptr = args[:fromRawPtr]
    """
  }

  /// Code inside of if clauses
  private static func buildInitializerBody(
    for record: OctoRecord,
    initializer: OctoFunction,
    options: GenerationOptions,
    ffiModuleName: String
  ) throws -> String {
    switch (initializer.initializerType) {
      case .selfArgument:
        var passedArgs: [String] = []
        passedArgs.reserveCapacity(initializer.arguments.count)
        var id = 0
        for i in 0..<initializer.arguments.count {
          if i == initializer.selfArgumentIndex! {
            passedArgs.append("@ptr")
          } else {
            passedArgs.append(initializer.arguments[i].type.rubyToC("args[\(id)]"))
            id += 1
          }
        }
        return """
        @ptr = \(ffiModuleName)::\(record.rubyFFIName).new
        \(ffiModuleName).\(initializer.rubyFFIName)(\(passedArgs.joined(separator: ", ")))
        """
      case .returnsSelf:
        return """
        @ptr = \(ffiModuleName).\(initializer.rubyFFIName)(\((0..<initializer.arguments.count).map {
          initializer.arguments[$0].type.rubyToC("args[\($0)]")
        }.joined(separator: ", ")))
        """
      case .none: throw GenerationError("Unexpected error: found 'none' initializer type for initializer \(record.ffiName!)", .ruby, origin: record.origin)
    }
  }

  private static func buildBody_arrayArgs(
    for record: OctoRecord,
    options: GenerationOptions,
    ffiModuleName: String,
    withMemberwiseInitializer memberwiseInitializer: ((_ record: OctoRecord, _ options: GenerationOptions, _ ffiModuleName: String) -> String)?
  ) throws -> String {
    var out = Self.buildBody_rawPtrWithArrayArgs(for: record, options: options)
    if let fn = memberwiseInitializer {
      out += "\n"
      out += fn(record, options, ffiModuleName)
    }
    if record.initializers.count == 0 {
      out += """
      \nelsif args.size == 0
      \(options.indent)@ptr = \(ffiModuleName)::\(record.rubyFFIName).new
      """
    } else {
      out += "\n"
      out += try record.initializers.map { initFn in
        return """
        elsif args.size == \(initFn.arguments.count)
        \(try indentCode(indent: options.indent, {
          try Self.buildInitializerBody(
            for: record,
            initializer: initFn,
            options: options,
            ffiModuleName: ffiModuleName
          )
        }))
        """
      }.joined(separator: "\n")
      out += """
      \nelsif args.size == 0
      \(options.indent)@ptr = \(ffiModuleName)::\(record.rubyFFIName).new
      """
    }
    let argCounts = record.initializers.map { initFn in "\(initFn.arguments.count)" }
    out += """
    \nelse
    \(options.indent)raise "Wrong number of arguments for initializer of \(record.rubyName) (given: #{args.size}, expected: \(argCounts.count == 0 ? "0" : argCounts.joined(separator: ", ")) or member-wise initializer)"
    end
    """
    return out
  }
}
