import OctoIntermediate
import OctoGenerateShared

extension OctoEnum: CCodeGenerator {
  func generateHeaderCode(options: GenerationOptions, in lib: OctoLibrary) throws -> String {
    let enumName = "_" + self.ffiName!
    //let typedefName = self.cTypedefName(options: options)

    var attributes: [String] = []
    if let prefix = self.enumPrefix {
      attributes.append("__attribute__((annotate(\"enumPrefix\", \"\(prefix)\")))")
    }

    attributes.append("__attribute__((annotate(\"rename\", \"\(self.bindingName!)\")))")

    return codeBuilder {
      if options.cOpts.useNamespaceInCxx {
        """
        #ifdef __cplusplus
        typedef enum \(enumName) \(self.bindingName!);
        #else
        typedef enum \(enumName) \(self.ffiName!);
        #endif
        """
      } else {
        "typedef enum \(enumName) \(self.ffiName!);"
      }

      """
      enum \(enumName) {
      \(indentCode(indent: options.indent, {
        self.cases.map { c in "\(c.ffiName!)\(c.value == nil ? "" : " = \(c.value!.literalValue)")" }.joined(separator: ", ")
      }))
      }\(attributes);
      """
    }
  }
}
