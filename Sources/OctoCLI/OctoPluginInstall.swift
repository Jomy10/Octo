import ArgumentParser

struct OctoPluginInstall: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "install",
    abstract: "Install an official plugin (unimplemented)",
    aliases: ["i"]
  )
}
