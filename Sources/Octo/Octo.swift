import Foundation
import ArgumentParser
import Clang

enum Language: ExpressibleByArgument {
  case c
  case cxx
  case swift
  case ruby
  case rust

  init?(argument: String) {
    let possibleValues: [Language] = [.c, .cxx, .swift, .ruby, .rust]
    guard let lang = possibleValues.first(where: { lang in
      "\(lang)" == argument
    }) else {
      return nil
    }
    self = lang
  }
}

enum IndentType: ExpressibleByArgument {
  case tabs
  case spaces

  init?(argument: String) {
    switch (argument) {
      case "tabs": self = .tabs
      case "spaces": self = .spaces
      default: return nil
    }
  }
}

struct Attribute {
  let symbolName: String
  let attributeName: String
  let arguments: [Substring]
  let originalArgument: String

  var asOctoAttribute: OctoAttribute {
    OctoAttribute(
      name: "octo:\(self.attributeName)",
      type: .annotate,
      params: arguments.map { arg in
        OctoAttribute.Parameter.string(arg)
      },
      origin: OctoOrigin(arg: originalArgument)
    )
  }
}

extension URL: ExpressibleByArgument {
  public init?(argument: String) {
    self = URL(fileURLWithPath: argument)
  }
}

@main
struct Octo: ParsableCommand {
  @Option(name: .customLong("from"), help: "The input language to create bindings for")
  var inputLanguage: Language = .c

  @Option(name: .customLong("to"), help: "The output language to create bindings in")
  var outputLanguage: Language

  @Option(name: .shortAndLong, help: "")
  var configFile: URL? = nil

  @Option(name: [.customLong("lib-name"), .customShort("n")], help: "The name of the library to be generated")
  var outputLibraryName: String

  @Option(name: [.customLong("output"), .customShort("o")], help: "Output path")
  var outputLocation: URL

  @Option(name: [.customLong("input"), .customShort("i")], help: "Input path")
  var inputLocation: URL

  @Option(name: [.long, .customShort("I")], help: """
  Specify a language specific option for the language being parsed (format: [langName]:[optName]{=value})
  # c
  - flag: a flag passed to clang for parsing
  - include: the header files whose symbols to include in the output
  - link: the library/libraries to link against
  """)
  var langInOpt: [String] = []

  @Option(name: [.long, .customShort("O")], help: "")
  var langOutOpt: [String] = []

  @Option(name: .shortAndLong, help: "The library/libraries to link against in the output")
  var link: [String] = []

  @Option(name: .long)
  var indentCount: Int = 2

  @Option(name: .long, help: "`tabs` or `spaces`")
  var indentType: IndentType = .spaces

  @Option(name: .shortAndLong, help: "Apply an attribute to a symbol, format: [symbol]>[attributeName]{=argList,}")
  var attribute: [String] = []

  func parseAttr(attr: String) -> Attribute {
    let s1: [Substring] = attr.split(separator: ">", maxSplits: 1)
    if s1.count != 2 { fatalError("Malformed attribute value '\(attr)'") }
    let attrName: Substring = s1[0]

    let s2: [Substring] = s1[1].split(separator: "=", maxSplits: 1)
    let symbolName: Substring = s2[0]
    let args: [Substring]
    if s2.count == 2 {
      args = s2[1].split(separator: ",")
    } else {
      args = []
    }

    return Attribute(
      symbolName: String(symbolName),
      attributeName: String(attrName),
      arguments: args,
      originalArgument: attr
    )
  }

  lazy var attributes: [Attribute] = {
    self.attribute.map { parseAttr(attr: $0) }
  }()

  lazy var indent: String = {
    String(repeating: self.indentType == .spaces ? " " : "\t", count: self.indentCount)
  }()

  var linkLibs: [String] {
    if self.link.count == 0 { return [self.outputLibraryName] }
    return self.link
  }

  enum LanguageOpt: Equatable {
    case value([Substring])
    case option
  }

  func parseLangOpt(opts: [String]) -> [Substring:[Substring:LanguageOpt]] {
    let opts: [[Substring]] = opts
      .map { $0.split(separator: ":") }

    if !(opts.allSatisfy { $0.count == 2 }) {
      fatalError("malformed language option: \(opts.first(where: { $0.count != 2 })!.joined(separator: ":")) (expected format: lang:opt=val or lang:opt)")
    }

    let opts2: [(Substring, [Substring])] = opts.map { opt in
      (opt[0], opt[1].split(separator: "="))
    }

    if !(opts2.allSatisfy { $0.1.count == 1 || $0.1.count == 2 }) {
      let nonSatisfyingOpt: (Substring, [Substring]) = opts2.first(where: { $0.1.count == 1 || $0.1.count == 2 })!
      let nonSatisfyingStr: String = nonSatisfyingOpt.0 + ":" + nonSatisfyingOpt.1.joined(separator: "=")
      fatalError("marformed option: \(nonSatisfyingStr) (expected format opt=val or opt)")
    }

    return opts2
      .reduce(
        into: [Substring:[Substring:LanguageOpt]](),
        { (res: inout [Substring:[Substring:LanguageOpt]], o: (Substring, [Substring])) in
      let (langName, opts) = o

      if res[langName] == nil {
        res[langName] = [:]
      }
      if opts.count == 2 {
        if .option == res[langName]?[opts[0]] {
          fatalError("\(opts[0]) specified as both an option and a value")
        }

        if res[langName]![opts[0]] == nil {
          res[langName]![opts[0]] = .value([])
        }
        guard case .value(var arr) = res[langName]![opts[0]] else {
          fatalError("unreachable")
        }
        arr.append(opts[1])
        res[langName]![opts[0]] = .value(arr)
      } else {
        if let langOpt = res[langName]![opts[0]] {
          if case .value(_) = langOpt {
            fatalError("\(opts[0]) specified as both an option and a value")
          }
        }

        res[langName]![opts[0]] = .option
      }
    })
  }

  lazy var languageInputOptions: [Substring:[Substring:LanguageOpt]] = {
    parseLangOpt(opts: self.langInOpt)
  }()

  lazy var languageOutputOptions: [Substring:[Substring:LanguageOpt]] = {
    parseLangOpt(opts: self.langOutOpt)
  }()

  lazy var cInOpts: [Substring:LanguageOpt] = {
    self.languageInputOptions["c"] ?? [:]
  }()

  static func getFlagArray(opts: [Substring:LanguageOpt], _  name: Substring) -> [Substring]? {
    guard let flags: LanguageOpt = opts[name] else { return nil }
    guard case .value(let values) = flags else {
      fatalError("Option '\(name)' should have a value")
    }
    return values
  }

  lazy var cIn_clangFlags: [Substring]? = {
    Self.getFlagArray(opts: self.cInOpts, "flag")
  }()

  lazy var cIn_includeHeaders: [Substring]? = {
    Self.getFlagArray(opts: self.cInOpts, "include")
  }()

  lazy var cIn_link: [Substring]? = {
    Self.getFlagArray(opts: self.cInOpts, "link")
  }()

  /// Main
  mutating func run() throws {
    // TODO: ParseConfigration(forLanguage: self.inputLanguage, withOptions: self)
    let languageSpecificConfig: ParseConfiguration.LanguageSpecificConfiguration
    switch (self.inputLanguage) {
      case .c:
        languageSpecificConfig = .c(ParseConfiguration.CConfig(
          headerFile: self.inputLocation,
          clangFlags: (self.cIn_clangFlags ?? []),
          includeHeaders: (self.cIn_includeHeaders ?? []),
          link: (self.cIn_link ?? []),
          logLevel: CXDiagnostic_Note,
          errorLevel: CXDiagnostic_Error
        ))
      default:
        fatalError("unimplemented")
    }
    let config = ParseConfiguration(
      outputLibraryName: self.outputLibraryName,
      outputLocation: self.outputLocation,//URL(fileURLWithPath: "./test/test.rb", relativeTo: URL.currentDirectory()),
      languageSpecificConfig: languageSpecificConfig
      //ParseConfiguration.LanguageSpecificConfiguration.c(ParseConfiguration.CConfig(
      //  headerFile: URL(fileURLWithPath: "test.h", relativeTo: URL.currentDirectory()),
      //  clangFlags: ["-I."],
      //  includeHeaders: ["*.h"],
      //  link: ["test"],
      //  logLevel: CXDiagnostic_Note,
      //  errorLevel: CXDiagnostic_Error
      //))
    )
    var library = try LanguageParser.parse(language: self.inputLanguage, config: config)
    defer { library.destroy() }

    for (i, attribute) in self.attributes.enumerated() {
      guard let objectId = library.getObject(name: attribute.symbolName) else {
        fatalError("Symbol '\(attribute.symbolName)' doesn't exist (passed as argument to --argument)")
      }
      library.addAttribute(to: objectId, attribute.asOctoAttribute, id: OctoLibrary.LangId.arg(i))
    }

    let generationOptions = GenerationOptions(
      indent: self.indent,
      libs: self.linkLibs
    )
    let code = CodeGenerator.generate(language: self.outputLanguage, lib: library, options: generationOptions)

    try code.write(to: self.outputLocation)
  }
}
