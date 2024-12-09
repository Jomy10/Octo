import Foundation
import TOMLKit
import OctoIntermediate
import ExpressionInterpreter
import OctoConfigKeys

extension OctoConfig: Decodable {
  init(decodingTOMLFile fileURL: URL) throws {
    let fileContents = try String(contentsOf: fileURL)
    self = try TOMLDecoder(strictDecoding: true)
      .decode(Self.self, from: fileContents)
  }

  enum TopLevelCodingKeys: String, CodingKey {
    case outputLibraryName = "libName"
    case link
    case input
    case output
    case renames
  }

  enum RenamesCodingKeys: String, CodingKey {
    case operations
  }

  init(from decoder: Decoder) throws {
    let parent = try decoder.container(keyedBy: TopLevelCodingKeys.self)
    let inputContainer = try parent.nestedContainer(keyedBy: InputCodingKeys.self, forKey: .input)
    let outputContainer = try parent.nestedContainer(keyedBy: Language.self, forKey: .output)

    self.outputLibraryName = try parent.decode(String.self, forKey: .outputLibraryName)
    self.link = try parent.decodeIfPresent([String].self, forKey: .link) ?? []

    self.inputLanguage = try inputContainer.decode(Language.self, forKey: .inputLanguage)
    if let loc = try? inputContainer.decode(URL.self, forKey: .inputLocation) {
      self.inputLocation = loc
    } else {
      self.inputLocation = URL(filePath: try inputContainer.decode(String.self, forKey: .inputLocation))
    }
    //self.langInOpts = try inputContainer.decodeIfPresent([try LanguageInputOptions.optionsType(forLanguage: self.inputLanguage)].self, forKey: .langInOpts) ?? []
    self.langInOpts = try LanguageInputOptions.decode(inputContainer, language: self.inputLanguage)
    self.attributes = try inputContainer.decodeIfPresent([Attribute].self, forKey: .attributes) ?? []

    var outputOptions: [Language:OutputOptions] = [:]
    for key in outputContainer.allKeys {
      outputOptions[key] = try outputContainer.decode(OutputOptions.self, forKey: key)
    }
    self.outputOptions = outputOptions

    self.renameOperations = try parent.decodeIfPresent([RenameValue].self, forKey: .renames)?
      .map { renameOperation in
        return try Program.compile(code: renameOperation.code)
      } ?? []
  }
}

/// A rename operation as defined in the TOML file
struct RenameValue: Decodable {
  let code: String
}

extension OctoConfig.OutputOptions: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: OutputCodingKeys.self)
    let lang = try Language(fromString: container.codingPath.last!.stringValue)

    if let loc = (try? container.decode(URL.self, forKey: .outputLocation)) {
      self.outputLocation = loc
    } else {
      self.outputLocation = URL(filePath: try container.decode(String.self, forKey: .outputLocation))
    }
    //self.langOutOpts = (try container.decodeIfPresent([try LanguageOutputOptions.optionsType(forLanguage: lang)].self, forKey: .langOutOpts) as [any LanguageOutputOption]) ?? []
    //let opts = try container.decodeIfPresent([String:Data].self, forKey: .langOutOpts) ?? []
    self.langOutOpts = try LanguageOutputOptions.decode(container, language: lang)
    self.indentCount = try container.decodeIfPresent(Int.self, forKey: .indentCount) ?? 2
    self.indentType = try container.decodeIfPresent(IndentType.self, forKey: .indentType) ?? .spaces
    self.renameOperations  = try container.decodeIfPresent([String].self, forKey: .renameOperations)?
      .map { renameOperation in
        return try Program.compile(code: renameOperation)
      } ?? []
  }
}
