import Plugins
import Foundation

#if DEBUG
let PLUGIN_PATH = Bundle.main.resourceURL! //URL(filePath: ".build/debug")
#else
#error("unimplemented")
#endif

public struct PluginManager {
  public static var `default` = PluginManager(pluginPath: PLUGIN_PATH)

  var plugins: [String:Plugin] = [:]
  let pluginPath: URL

  public init(pluginPath: URL) {
    self.pluginPath = pluginPath
  }

  /// Get a plugin that is already loded, or load the plugin
  public mutating func getPlugin(
    named name: String,
    initData: UnsafeMutableRawPointer? = nil,
    initFunctionName: String? = nil,
    deinitData: UnsafeMutableRawPointer? = nil,
    deinitFunctionName: String? = nil
  ) throws -> Plugin {
    if let plugin = self.plugins[name] {
      return plugin
    } else {
      let plugin = try Plugin(name: name, location: self.pluginPath, initData: initData, initFunctionName: initFunctionName, deinitData: deinitData, deinitFunctionName: deinitFunctionName)
      self.plugins[name] = plugin
      return plugin
    }
  }

  public mutating func getParserPlugin(languageName: String) throws -> Plugin {
    return try ((try? self.getPlugin(named: "\(languageName)Parser")) ?? (try self.getPlugin(named: "Octo\(languageName)Parser")))
  }
}
