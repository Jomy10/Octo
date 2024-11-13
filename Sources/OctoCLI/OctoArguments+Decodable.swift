import Foundation
import Octo

extension OctoArguments: Decodable {
  enum CodingKeys: String, CodingKey {
    case input
    case output
  }

  enum InputCodingKeys: String, CodingKey {
    case inputLanguage = "language"
    case inputLocation = "location"
    case langInOpt = "options"
    case attributes
  }

  enum OutputCodingKeys: String, CodingKey {
    case outputLanguage = "language"
    case outputLocation = "location"
    case langOutOpt = "options"
    case outputLibraryName = "libName"
    case link
    case indentCount
    case indentType
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let input = try container.nestedContainer(keyedBy: InputCodingKeys.self, forKey: .input)
    let output = try container.nestedContainer(keyedBy: OutputCodingKeys.self, forKey: .output)


    self.inputLanguage = try input.decode(Language.self, forKey: .inputLanguage)
    self.inputLocation = try input.decode(URL.self, forKey: .inputLocation)
    self.langInOpt = try input.decodeIfPresent(LanguageOptions.self, forKey: .langInOpt)?.inner ?? []
    self.attributes = try input.decodeIfPresent([Attribute].self, forKey: .attributes) ?? []
    self.outputLanguage = try output.decode(Language.self, forKey: .outputLanguage)
    self.outputLocation = try output.decode(URL.self, forKey: .outputLocation)
    self.langOutOpt = try output.decodeIfPresent(LanguageOptions.self, forKey: .langOutOpt)?.inner ?? []
    self.outputLibraryName = try output.decode(String.self, forKey: .outputLibraryName)
    self.link = try output.decodeIfPresent([String].self, forKey: .link) ?? []
    self.indentCount = try output.decodeIfPresent(Int.self, forKey: .indentCount) ?? 2
    self.indentType = try output.decodeIfPresent(IndentType.self, forKey: .indentType) ?? .spaces
  }
}
