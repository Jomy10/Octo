import Foundation
import Octo
import TOMLKit
import ArgumentParser

/// Arguments that can be used from the CLI and in the configuration file
struct OctoArguments: ParsableArguments {
  // Input (parse) options //

  @Option(name: .customLong("from"), help: "The input language to create bindings for")
  var inputLanguage: Language? = nil // required if no config file specified

  @Option(name: [.customShort("i"), .customLong("input-location")], help: "Input path")
  var inputLocation: URL? = nil // required if no config file specified

  @Option(name: [.customShort("I"), .long], help: """
  Specify a language specific option for the language being parsed (format: <langName>:<optName>[=value])
  # c
  - flag: a flag passed to clang for parsing
  - include: the header files whose symbols to include in the output (default: all header files included in the provided header)
  - logLevel
  - errorLevel
  """)
  var langInOpt: [LanguageOption] = []

  @Option(name: [.short, .customLong("attribute")], help: "Apply an attribute to a symbol, format: [symbol]>[attributeName]{=argList,}")
  var attributes: [Attribute] = []

  // Output (generation) options //

  @Option(name: .customLong("to"), help: "The output language to create bindings in")
  var outputLanguage: Language? = nil // required if no config file specified

  @Option(name: [.customLong("output"), .customShort("o")], help: "Output path")
  var outputLocation: URL? = nil // required if no config file specified

  @Option(name: [.long, .customShort("O")], help: "")
  var langOutOpt: [LanguageOption] = []

  @Option(name: [.customLong("lib-name"), .customShort("n")], help: "The name of the library to be generated")
  var outputLibraryName: String? = nil // required if no config file specified

  @Option(name: .shortAndLong, help: "The library/libraries to link against in the output")
  var link: [String] = []

  @Option(name: .long)
  var indentCount: Int = 2

  @Option(name: .long, help: "`tabs` or `spaces`")
  var indentType: IndentType = .spaces


//  mutating func validate() throws {
//    print("Validating arguments")
//  }

//  var indent: String {
//    String(repeating: self.indentType == .spaces ? " " : "\t", count: self.indentCount)
//  }

//  /// The library/libraries to link against
//  var linkLibs: [String] {
//    if self.link.count == 0 { return [self.outputLibraryName] }
//    return self.link
//  }

//  // Parsing language options //

//  static func getLangOptionArray(opts: [LanguageOption], _  name: Substring) -> [Substring] {
//    let options: [LanguageOption] = opts.filter { (opt: LanguageOption) in opt.name == name }
//    return options.map { (opt: LanguageOption) in
//      guard let value = opt.value else {
//        fatalError("\(name) should have a value")
//      }
//      return value
//    }
//  }

//  static func getLangOption(opts: [LanguageOption], _ name: Substring) -> Substring? {
//    let options = opts.filter { opt in opt.name == name }
//    if options.count > 1 {
//      fatalError("Option \(name) specified multiple times")
//    }
//    return options.first?.value
//  }

//  static func getLangFlag(opts: [LanguageOption], _ name: Substring) -> Bool {
//    let options = opts.filter { opt in opt.name == name }
//    if options.count > 1 {
//      fatalError("Flag \(name) specified multiple times")
//    }
//    return options.count == 1
//  }

//  // Parsed language input options //

//  //== C ==//

//  lazy var cInOpts: [LanguageOption] = {
//    return self.langInOpt.filter { opt in
//      opt.language == .c
//    }
//  }()

//  lazy var cIn_clangFlags: [Substring] = {
//    Self.getLangOptionArray(opts: self.cInOpts, "flag")
//  }()

//  lazy var cIn_includeHeaders: [Substring] = {
//    Self.getLangOptionArray(opts: self.cInOpts, "include")
//  }()

//  lazy var cIn_logLevel: ClangDiagnostic? = {
//    if let logLevel = Self.getLangOption(opts: self.cInOpts, "logLevel") {
//      guard let l = ClangDiagnostic(fromString: logLevel) else {
//        fatalError("Invalid clang diagnostic for logLevel '\(logLevel)'")
//      }
//      return l
//    } else {
//      return nil
//    }
//  }()

//  lazy var cIn_errorLevel: ClangDiagnostic? = {
//    if let errorLevel = Self.getLangOption(opts: self.cInOpts, "errorLevel") {
//      guard let l = ClangDiagnostic(fromString: errorLevel) else {
//        fatalError("Invalid clang diagnostic for errorLevel '\(errorLevel)'")
//      }
//      return l
//    } else {
//      return nil
//    }
//  }()

//  //init() {}

//  //init(
//  //  inputLanguage: Language,
//  //  inputLocation: URL,
//  //  langInOpt: [LanguageOption]?,
//  //  attributes: [Attribute]?,

//  //  outputLanguage: Language,
//  //  outputLocation: URL,
//  //  langOutOpt: [LanguageOption]?,
//  //  outputLibraryName: String,
//  //  link: [String]?,
//  //  indentCount: Int?,
//  //  indentType: IndentType?
//  //) {
//  //  self.inputLanguage = inputLanguage
//  //  self.inputLocation = inputLocation
//  //  self.langInOpt = langInOpt ?? []
//  //  self.attributes = attributes ?? []

//  //  self.outputLanguage = outputLanguage
//  //  self.outputLocation = outputLocation
//  //  self.langOutOpt = langOutOpt ?? []
//  //  self.outputLibraryName = outputLibraryName
//  //  self.link = link ?? []
//  //  self.indentCount = indentCount ?? 2
//  //  self.indentType = indentType ?? .spaces
//  //}
}
