import Foundation
import Octo
import TOMLKit

extension Language: CodingKey {}

// Output of either the command line or TOML
struct OctoArgumentsParsed {
  var outputLibraryName: String
  var link: [String]

  // Input (parse) options //
  var inputLanguage: Language
  var inputLocation: URL
  var langInOpts: [LanguageOption]
  var attributes: [Attribute]

  // Output (generation) options //
  var outputOptions: [Language:OutputOptions]

  struct OutputOptions: Decodable {
    var outputLocation: URL
    var langOutOpts: [LanguageOption]
    //var link: [String] TODO: override
    var indentCount: Int
    var indentType: IndentType

    enum CodingKeys: String, CodingKey {
      case outputLocation = "location"
      case langOutOpts = "options"
      case indentCount
      case indentType
    }

    var indent: String {
      String(repeating: self.indentType == .spaces ? " " : "\t", count: self.indentCount)
    }

    init(
      outputLocation: URL,
      langOutOpts: [LanguageOption],
      //outputLibraryName: String,
      //link: [String],
      indentCount: Int,
      indentType: IndentType
    ) {
      self.outputLocation = outputLocation
      self.langOutOpts = langOutOpts
      //self.outputLibraryName = outputLibraryName
      //self.link = link
      self.indentCount = indentCount
      self.indentType = indentType
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      //self.outputLanguage = try container.decode(Language.self, forKey: .containerLanguage)
      self.outputLocation = try URL(fileURLWithPath: container.decode(String.self, forKey: .outputLocation))
      self.langOutOpts = try container.decodeIfPresent([TOMLLanguageOption].self, forKey: .langOutOpts)?.map { $0.asLanguageOption } ?? []
      //self.outputLibraryName = try container.decode(String.self, forKey: .containerLibraryName)
      //self.link = try container.decodeIfPresent([String].self, forKey: .link) ?? []
      self.indentCount = try container.decodeIfPresent(Int.self, forKey: .indentCount) ?? 2
      self.indentType = try container.decodeIfPresent(IndentType.self, forKey: .indentType) ?? .spaces
    }
  }

  init(fromCommandLineArguments args: OctoArguments) {
    self.inputLanguage = args.inputLanguage!
    self.inputLocation = args.inputLocation!
    self.langInOpts = args.langInOpt
    self.attributes = args.attributes

    self.outputOptions = [:]
    self.outputOptions[args.outputLanguage!] = OutputOptions(
      outputLocation: args.outputLocation!,
      langOutOpts: args.langOutOpt,
      //outputLibraryName: args.outputLibraryName!,
      //link: args.link,
      indentCount: args.indentCount,
      indentType: args.indentType
    )

    self.link = args.link
    self.outputLibraryName = args.outputLibraryName!
  }

  init(decodingTOMLFile fileURL: URL) throws {
    let fileContents = try String(contentsOf: fileURL)
    self = try TOMLDecoder().decode(Self.self, from: fileContents)
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
    case link
    case outputLibraryName = "libName"
  }

  enum InputCodingKeys: String, CodingKey {
    case inputLanguage = "language"
    case inputLocation = "location"
    case langInOpt = "options"
    case attributes
  }

  //enum OutputCodingKeys: String, CodingKey {
  //  case outputLanguage = "language"
  //  case outputLocation = "location"
  //  case langOutOpt = "options"
  //  case outputLibraryName = "libName"
  //  case link
  //  case indentCount
  //  case indentType
  //}

  init(from decoder: Decoder) throws {
    print(decoder)

    let container = try decoder.container(keyedBy: CodingKeys.self)
    let input = try container.nestedContainer(keyedBy: InputCodingKeys.self, forKey: .input)
    let output = try container.nestedContainer(keyedBy: Language.self, forKey: .output)

    self.link = try container.decodeIfPresent([String].self, forKey: .link) ?? []
    self.outputLibraryName = try container.decode(String.self, forKey: .outputLibraryName)

    self.inputLanguage = try input.decode(Language.self, forKey: .inputLanguage)
    self.inputLocation = try URL(fileURLWithPath: input.decode(String.self, forKey: .inputLocation))
    self.langInOpts = try input.decodeIfPresent([TOMLLanguageOption].self, forKey: .langInOpt)?.map { $0.asLanguageOption } ?? []
    self.attributes = try input.decodeIfPresent([Attribute].self, forKey: .attributes) ?? []

    self.outputOptions = [:]
    for key in output.allKeys {
      self.outputOptions[key] = try output.decode(OutputOptions.self, forKey: key)
    }
  }
}

// https://github.com/apple/swift-argument-parser/issues/683
struct OctoArgumentsParsedContainer: Decodable {
  var args: OctoArgumentsParsed? = nil

  init() {}

  init(from decoder: Decoder) throws {}
}
