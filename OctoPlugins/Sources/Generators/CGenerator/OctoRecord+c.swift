import OctoIntermediate
import OctoGenerateShared

extension OctoRecord: CCodeGenerator {
  func cTypedefName(options: GenerationOptions) -> String {
    if (options.cOpts.prefixTypes) {
      return "\(options.moduleName)_\(self.bindingName!)"
    } else {
      return "\(self.bindingName!)"
    }
  }

  func cRecordName(options: GenerationOptions) -> String {
    if options.cOpts.prefixTypes {
      return "_\(options.moduleName)_\(self.ffiName!)"
    } else {
      return "_\(self.ffiName!)"
    }
  }

  func generateHeaderCode(options: GenerationOptions, in lib: OctoLibrary) throws -> String {
    let recordName = self.cRecordName(options: options)

    var attributes = ""
    let recordType: String
    switch (self.type) {
      case .`struct`: recordType = "struct"
      case .union: recordType = "union"
      case .taggedUnion:
        attributes += " __attribute__((annotate(\"taggedUnion\")))"
        recordType = "struct"
    }

    let typedefName = self.cTypedefName(options: options)

    return codeBuilder {
      if options.cOpts.useNamespaceInCxx {
        """
        #ifdef __cplusplus
        typedef struct \(recordName) \(self.bindingName!);
        #else
        typedef struct \(recordName) \(typedefName);
        #endif
        """
      } else {
        "typedef struct \(recordName) \(typedefName);"
      }

      """
      \(recordType) \(recordName) {
      \(indentCode(indent: options.indent, {
        for field in self.fields {
          if let caseName = field.taggedUnionCaseName {
            "__attribute__((annotate(\"taggedUnionType\", \"\(caseName)\")))" // TODO: enum prefix!
          }
          field.type.cType(options: options, name: field.bindingName!) + ";"
        }
      }))
      }\(attributes);
      """
    }
  }
}
