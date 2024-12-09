import Foundation
import ArgumentParser

@main
struct Octo: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Polyglot binding generator",
    version: "0.1.0",
    subcommands: [OctoPluginManager.self, OctoGenerate.self],
    defaultSubcommand: OctoGenerate.self
  )
}
