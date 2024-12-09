import ArgumentParser

struct OctoPluginManager: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "plugins",
    abstract: "List installed plugins, install new plugins, ...",
    subcommands: [PluginDoctor.self],
    aliases: ["plugin", "plug"]
  )

  mutating func run() throws {
    // release to download from
    print(Octo.configuration.version)
    // if release doesn't exist => you are on a nightly version of Octo, cannot download -> build from source instead
  }
}
