import Octo
import Foundation
import ArgumentParser

// for options: https://apple.github.io/swift-argument-parser/documentation/argumentparser/declaringarguments#Alternative-single-value-parsing-strategies

@main
struct Octo: ParsableCommand {
  // Generic options //
  @Flag(name: [.short, .customLong("verbose")], help: "Log level for Octo")
  var verboseLevel: Int

  var verbose: Bool {
    return verboseLevel == 1
  }

  var veryVerbose: Bool {
    return verboseLevel > 1
  }

  // Configfle //

  @Option(name: .shortAndLong, help: "")
  var configFile: URL? = nil

  // Language options //
  @OptionGroup var cliArgs: OctoArguments

  var _args: OctoArgumentsParsedContainer = OctoArgumentsParsedContainer()

  lazy var args: OctoArgumentsParsed = {
    guard let args = self._args.args else {
      fatalError("bug")
    }
    return args
  }()

  mutating func validate() throws {
    if self.configFile == nil {
      if self.cliArgs.inputLanguage == nil {
        throw ValidationError("Missing expected argument '--input-language <input-language>'")
      }
      if self.cliArgs.inputLocation == nil {
        throw ValidationError("Missing expected argument '--input-location <input-location>'")
      }
      if self.cliArgs.outputLanguage == nil {
        throw ValidationError("Missing expected argument '--output-language <output-language>'")
      }
      if self.cliArgs.outputLocation == nil {
        throw ValidationError("Missing expected argument '--output-location <output-location>'")
      }
      if self.cliArgs.outputLibraryName == nil {
        throw ValidationError("Missing expected argument '--lib-name <lib-name>'")
      }
    }
  }

  mutating func initArgs() throws {
    if let configFile = self.configFile {
      self._args.args = try OctoArgumentsParsed(decodingTOMLFile: configFile)
    } else {
      self._args.args = OctoArgumentsParsed(fromCommandLineArguments: self.cliArgs)
    }
  }
}
