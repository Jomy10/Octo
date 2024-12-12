import OctoIntermediate
import OctoGenerateShared

extension OctoFunction: CCodeGenerator {
  func generateHeaderCode(options: GenerationOptions, in lib: OctoLibrary) throws -> String {
    """
    \(self.returnType.cType(options: options)) \(self.ffiName!)(\(self.arguments.map { arg in
      var attrs = ""
      if arg.isSelfArgument {
        attrs += "__attribute__((annotate(\"self\"))) "
      }
      if arg.namedArgument {
        attrs += "__attribute__((annotate(\"namedArgument\"))) "
      }

      return attrs + arg.type.cType(options: options, name: arg.bindingName!)
    }.joined(separator: ", ")));
    """
    // functionname should be ffiName and rename attribute to bindingName
  }
}
