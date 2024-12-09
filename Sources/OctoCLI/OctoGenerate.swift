import ArgumentParser

struct OctoGenerate: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "generate",
    abstract: "Generate bindings",
    discussion: "Generate bindings from language X to language Y. This can either be done using a config file, or using the manual options",
    aliases: ["g"]
  )

  @Flag(name: [.short, .customLong("verbose")], help: "Log level for Octo")
  var verbosityLevel: Int

  @OptionGroup(title: "With config file")
  var configFileArg: OctoConfigFileArguments

  @OptionGroup(title: "Manual options")
  var configArgs: OctoManualArguments
}
