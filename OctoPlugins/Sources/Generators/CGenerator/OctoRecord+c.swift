import OctoIntermediate
import OctoGenerateShared

extension OctoRecord: CCodeGenerator {
  @available(*, deprecated)
  func cTypedefName(options: GenerationOptions) -> String {
    fatalError()
    // ffiName, bindingName in c++ if namespaces
  }

  @available(*, deprecated)
  func cRecordName(options: GenerationOptions) -> String {
    fatalError()
    // ffiName, bindingName in c++ if namespaces
  }

  func generateHeaderCode(options: GenerationOptions, in lib: OctoLibrary) throws -> String {
    let recordName = "_" + self.ffiName!

    var attributes = ""
    let recordType: String
    switch (self.type) {
      case .`struct`: recordType = "struct"
      case .union: recordType = "union"
      case .taggedUnion:
        attributes += " __attribute__((annotate(\"taggedUnion\")))"
        recordType = "struct"
    }

    attributes.append("__attribute__((annotate(\"rename\", \"\(self.bindingName!)\")))")

    return codeBuilder {
      if options.cOpts.useNamespaceInCxx {
        """
        #ifdef __cplusplus
        typedef \(recordType) \(recordName) \(self.bindingName!);
        #else
        typedef \(recordType) \(recordName) \(self.ffiName!);
        #endif
        """
      } else {
        "typedef \(recordType) \(recordName) \(self.ffiName!);"
      }

      """
      \(recordType) \(recordName) {
      \(indentCode(indent: options.indent, {
        for field in self.fields {
          if let caseName = field.taggedUnionCaseName {
            "__attribute__((annotate(\"taggedUnionType\", \"\(caseName)\")))" // TODO: enum prefix!
          }
          field.type.cType(options: options, name: field.bindingName!, isRecordField: true) + ";"
        }
      }))
      }\(attributes);
      """
    }
  }
}
