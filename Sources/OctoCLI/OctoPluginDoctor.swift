import ArgumentParser
import PluginManager
import OctoIO

struct PluginDoctor: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "doctor",
    abstract: "See the status of installed plugins",
    discussion: "The plugin doctor shows a list of all installed plugins. You can also list non-installed official plugins",
    aliases: ["doc"]
  )

  @Flag(name: .long, inversion: .prefixedNo, help: "Show parser plugins")
  var parsers: Bool = true

  @Flag(name: .long, inversion: .prefixedNo, help: "Show generator plugins")
  var generators: Bool = true

  @Flag(name: .shortAndLong, inversion: .prefixedNo, help: "Show non-installed official plugins")
  var official: Bool = false

  @Flag(name: .shortAndLong, inversion: .prefixedNo, help: "Validate if the plugin exports the correct functions")
  var validate: Bool = false

  func printPluginInfo(_ plugins: [PluginInfo]) {
    for plugin in plugins {
      if plugin.file != nil {
        if self.validate {
          // TODO -> in red if couldn't validate
        }
        print(" ✔ \(plugin.name)".green(), to: .stderr)
      } else {
        print(" ✗ \(plugin.name)".yellow(), to: .stderr)
      }
    }
  }

  mutating func run() throws {
    if self.validate {
      print("[WARN] Validation is not yet implemented")
    }

    let plugins: [PluginInfo] = try PluginManager.default.listPlugins()

    var parsers = plugins.filter { $0.type == .parser }
    var generators = plugins.filter { $0.type == .generator }

    if self.official {
      ["Swift", "C"].forEach { offP in
        if !parsers.contains(where: { $0.name == offP }) {
          parsers.append(PluginInfo(name: offP, type: .parser))
        }
      }

      ["Swift", "Ruby"].forEach { offP in
        if !generators.contains(where: { $0.name == offP }) {
          generators.append(PluginInfo(name: offP, type: .generator))
        }
      }
    }

    if self.parsers {
      print("Parsers".blue(), to: .stderr)
      self.printPluginInfo(parsers)
    }

    if self.generators {
      print("Generators".blue(), to: .stderr)
      self.printPluginInfo(generators)
    }
  }
}
