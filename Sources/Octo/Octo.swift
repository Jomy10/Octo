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

@main
struct Octo: ParsableCommand {
  @Option(name: .long, help: "The input language to create bindings for")
  var inputLanguage: Language = .c

  @Option(name: .long, help: "The output language to create bindings in")
  var outputLanguage: Language = .ruby

  /// Main
  mutating func run() throws {
    // TODO: ParseConfigration(forLanguage: self.inputLanguage, withOptions: self)
    let config = ParseConfiguration(
      outputLibraryName: "Test",
      outputLocation: URL(fileURLWithPath: "./test/test.rb", relativeTo: URL.currentDirectory()),
      languageSpecificConfig: ParseConfiguration.LanguageSpecificConfiguration.c(ParseConfiguration.CConfig(
        headerFile: URL(fileURLWithPath: "test.h", relativeTo: URL.currentDirectory()),
        clangFlags: ["-I."],
        includeHeaders: ["*.h"],
        link: ["test"],
        logLevel: CXDiagnostic_Note,
        errorLevel: CXDiagnostic_Error
      ))
    )
    let library = try! LanguageParser.parse(language: self.inputLanguage, config: config)
    defer { library.destroy() }

    let generationOptions = GenerationOptions(
      indent: "  ",
      libs: ["test"] // from config
    )
    let rubyCode = CodeGenerator.generate(language: self.outputLanguage, lib: library, options: generationOptions)

    print(rubyCode)
  }
}
