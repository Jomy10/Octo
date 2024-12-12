import OctoIntermediate
import OctoGenerateShared

extension OctoEnum: CCodeGenerator {
  func cTypedefName(options: GenerationOptions) -> String {
    if (options.cOpts.prefixTypes) {
      return "\(options.moduleName)_\(self.bindingName!)"
    } else {
      return "\(self.bindingName!)"
    }
  }

  func cEnumName(options: GenerationOptions) -> String {
    if (options.cOpts.prefixTypes) {
      return "\(options.moduleName)_\(self.bindingName!)"
    } else {
      return "\(self.bindingName!)"
    }
  }

  func generateHeaderCode(options: GenerationOptions, in lib: OctoLibrary) throws -> String {
    let enumName = self.cEnumName(options: options)
    let typedefName = self.cTypedefName(options: options)

    var prefixAttribute = ""
    if let prefix = self.enumPrefix {
      prefixAttribute = "__attribute__((annotate(\"enumPrefix\", \"\(prefix)\")))"
    }

    return """
    typedef enum \(enumName) \(typedefName);
    enum \(enumName) {
    \(indentCode(indent: options.indent, {
      self.cases.map { c in "\(c.ffiName!)\(c.value == nil ? "" : " = \(c.value!.literalValue)")" }.joined(separator: ", ")
    }))
    }\(prefixAttribute);
    """
  }
}
