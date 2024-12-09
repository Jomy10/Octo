import Plugins
import Foundation

//#if DEBUG
//let PLUGIN_PATH = Bundle.main.resourceURL! //URL(filePath: ".build/debug")
//#else
//#error("unimplemented")
//#endif

public struct PluginManager {
  public static var `default` = PluginManager(pluginPath: PLUGIN_PATH)

  var plugins: [String:Plugin] = [:]
  // TODO: rename to pluginURL for consistency with stdlib
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
    return try ((try? self.getPlugin(named: "Octo\(languageName)Parser")) ?? (try self.getPlugin(named: "\(languageName)Parser")))
  }

  public mutating func getGeneratorPlugin(languageName: String) throws -> Plugin {
    return try ((try? self.getPlugin(named: "Octo\(languageName)Generator")) ?? (try self.getPlugin(named: "\(languageName)Generator")))
  }

  public func listPlugins() throws -> [PluginInfo] {
    let items: [URL] = try FileManager.default.contentsOfDirectory(at: self.pluginPath, includingPropertiesForKeys: nil)
    let parserRegex = try Regex("lib(Octo)?(?<name>.*)Parser\\.\(Plugin.libExt)")
    let generatorRegex = try Regex("lib(Octo)?(?<name>.*)Generator\\.\(Plugin.libExt)")
    return items.filter { (item: URL) in
      item.pathExtension == Plugin.libExt
    }.map { (item: URL) in
      let fileName: String = item.lastPathComponent
      if let result = try? parserRegex.wholeMatch(in: fileName) {
        return PluginInfo(
          name: String(result["name"]!.substring!),
          file: item,
          type: .parser
        )
      } else if let result = try? generatorRegex.wholeMatch(in: fileName) {
        return PluginInfo(
          name: String(result["name"]!.substring!),
          file: item,
          type: .generator
        )
      } else {
        // TODO: log (warn invalid name)
        return nil
      }
    }.filter { $0 != nil }
    .map { $0! }
  }
}

public struct PluginInfo {
  public let name: String
  public let file: URL?
  public let type: PluginType

  public init(
    name: String,
    file: URL? = nil,
    type: PluginType
  ) {
    self.name = name
    self.file = file
    self.type = type
  }

  public enum PluginType: Equatable {
    case parser
    case generator
  }
}
