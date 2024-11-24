import Foundation
import ArgumentParser

@main
struct Octo: ParsableCommand {
  @Flag(name: [.short, .customLong("verbose")], help: "Log level for Octo")
  var verbosityLevel: Int

  @OptionGroup(title: "With config file")
  var configFileArg: OctoConfigFileArguments

  @OptionGroup(title: "Manual options")
  var configArgs: OctoManualArguments
}
