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
  @OptionGroup var args: OctoArguments
}
