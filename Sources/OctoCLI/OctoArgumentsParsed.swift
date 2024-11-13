import Foundation
import Octo
import TOMLKit

// TODO: proper parsing of some arguments
struct OctoArgumentsParsed {
  // Input (parse) options //
  var inputLanguage: Language
  var inputLocation: URL
  var langInOpts: [LanguageOption]
  var attributes: [Attribute]

  // Output (generation) options //
  var outputLanguage: Language
  var outputLocation: URL
  var langOutOpts: [LanguageOption]
  var outputLibraryName: String
  var link: [String]
  var indentCount: Int
  var indentType: IndentType

  init(fromCommandLineArguments args: OctoArguments) {
    self.inputLanguage = args.inputLanguage!
    self.inputLocation = args.inputLocation!
    self.langInOpts = args.langInOpt
    self.attributes = args.attributes
    self.outputLanguage = args.outputLanguage!
    self.outputLocation = args.outputLocation!
    self.langOutOpts = args.langOutOpt
    self.outputLibraryName = args.outputLibraryName!
    self.link = args.link
    self.indentCount = args.indentCount
    self.indentType = args.indentType
  }

  init(decodingTOMLFile fileURL: URL) throws {
    let fileContents = try String(contentsOf: fileURL)
    self = try TOMLDecoder().decode(Self.self, from: fileContents)
  }

  var indent: String {
    String(repeating: self.indentType == .spaces ? " " : "\t", count: self.indentCount)
  }

  /// The library/libraries to link against
  var linkLibs: [String] {
    if self.link.count == 0 { return [self.outputLibraryName] }
    return self.link
  }

  // Parsing language options //

  static func getLangOptionArray(opts: [LanguageOption], _  name: Substring) -> [Substring] {
    let options: [LanguageOption] = opts.filter { (opt: LanguageOption) in opt.name == name }
    return options.map { (opt: LanguageOption) in
      guard let value = opt.value else {
        fatalError("\(name) should have a value")
      }
      return value
    }
  }

  static func getLangOption(opts: [LanguageOption], _ name: Substring) -> Substring? {
    let options = opts.filter { opt in opt.name == name }
    if options.count > 1 {
      fatalError("Option \(name) specified multiple times")
    }
    return options.first?.value
  }

  static func getLangFlag(opts: [LanguageOption], _ name: Substring) -> Bool {
    let options = opts.filter { opt in opt.name == name }
    if options.count > 1 {
      fatalError("Flag \(name) specified multiple times")
    }
    return options.count == 1
  }

  // Parsed language input options //

  //== C ==//

  //lazy var cInOpts: [LanguageOption] = {
  //  return self.langInOpt.filter { opt in
  //    opt.language == .c
  //  }
  //}()

  var cIn_clangFlags: [Substring] {
    Self.getLangOptionArray(opts: self.langInOpts, "flag")
  }

  var cIn_includeHeaders: [Substring] {
    Self.getLangOptionArray(opts: self.langInOpts, "include")
  }

  var cIn_logLevel: ClangDiagnostic? {
    if let logLevel = Self.getLangOption(opts: self.langInOpts, "logLevel") {
      guard let l = ClangDiagnostic(fromString: logLevel) else {
        fatalError("Invalid clang diagnostic for logLevel '\(logLevel)'")
      }
      return l
    } else {
      return nil
    }
  }

  var cIn_errorLevel: ClangDiagnostic? {
    if let errorLevel = Self.getLangOption(opts: self.langInOpts, "errorLevel") {
      guard let l = ClangDiagnostic(fromString: errorLevel) else {
        fatalError("Invalid clang diagnostic for errorLevel '\(errorLevel)'")
      }
      return l
    } else {
      return nil
    }
  }

}

extension OctoArgumentsParsed: Decodable {
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
    print(decoder)

    let container = try decoder.container(keyedBy: CodingKeys.self)
    let input = try container.nestedContainer(keyedBy: InputCodingKeys.self, forKey: .input)
    let output = try container.nestedContainer(keyedBy: OutputCodingKeys.self, forKey: .output)

    self.inputLanguage = try input.decode(Language.self, forKey: .inputLanguage)
    self.inputLocation = try URL(fileURLWithPath: input.decode(String.self, forKey: .inputLocation))
    self.langInOpts = try input.decodeIfPresent([TOMLLanguageOption].self, forKey: .langInOpt)?.map { $0.asLanguageOption } ?? []
    self.attributes = try input.decodeIfPresent([Attribute].self, forKey: .attributes) ?? []
    self.outputLanguage = try output.decode(Language.self, forKey: .outputLanguage)
    self.outputLocation = try URL(fileURLWithPath: output.decode(String.self, forKey: .outputLocation))
    self.langOutOpts = try output.decodeIfPresent([TOMLLanguageOption].self, forKey: .langOutOpt)?.map { $0.asLanguageOption } ?? []
    self.outputLibraryName = try output.decode(String.self, forKey: .outputLibraryName)
    self.link = try output.decodeIfPresent([String].self, forKey: .link) ?? []
    self.indentCount = try output.decodeIfPresent(Int.self, forKey: .indentCount) ?? 2
    self.indentType = try output.decodeIfPresent(IndentType.self, forKey: .indentType) ?? .spaces
  }
}

// https://github.com/apple/swift-argument-parser/issues/683
struct OctoArgumentsParsedContainer: Decodable {
  var args: OctoArgumentsParsed? = nil

  init() {}

  init(from decoder: Decoder) throws {}
}
