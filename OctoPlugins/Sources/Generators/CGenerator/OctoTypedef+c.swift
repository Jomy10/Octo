import OctoIntermediate
import OctoGenerateShared

extension OctoTypedef: CCodeGenerator {
  func generateHeaderCode(options: GenerationOptions, in lib: OctoLibrary) throws -> String {
    "typedef \(self.refersTo.cType(options: options, name: self.bindingName!));"
  }
}
