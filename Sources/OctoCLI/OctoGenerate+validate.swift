import OctoIO
import ArgumentParser

fileprivate extension ValidationError {
  private static func formatShouldntExist(_ argName: String) -> String {
    "Value for \(argName) shouldn't be specified when `--config` argument is used"
  }

  static func exists<T>(_ exists: [T]) -> Bool {
    exists.count != 0
  }

  static func exists<T>(_ exists: T?) -> Bool {
    exists != nil
  }

  static func shouldntExist<T>(_ val: [T], _ argName: String) throws {
    if exists(val) {
      throw Self(Self.formatShouldntExist(argName))
    }
  }

  static func shouldntExist<T>(_ val: T?, _ argName: String) throws {
    if exists(val) {
      throw Self(Self.formatShouldntExist(argName))
    }
  }

  private static func formatShouldExist(_ argName: String) -> String {
    "expected argument \(argName) to be specified or a config file to be specified"
  }

  static func shouldExist<T>(_ val: [T], _ argName: String) throws {
    if !exists(val) {
      throw Self(Self.formatShouldExist(argName))
    }
  }

  static func shouldExist<T>(_ val: T?, _ argName: String) throws {
    if !exists(val) {
      throw Self(Self.formatShouldExist(argName))
    }
  }
}

extension OctoGenerate {
  mutating func validate() throws {
    let args = self.configArgs
    if self.configFileArg.configFile == nil && [
      ValidationError.exists(args.inputLanguage),
      ValidationError.exists(args.inputLocation),
      ValidationError.exists(args.outputLanguage),
      ValidationError.exists(args.outputLocation),
      ValidationError.exists(args.outputLibraryName)
    ].allSatisfy({ !$0 }) {
      throw CleanExit.helpRequest(Self.self)
    } else if self.configFileArg.configFile != nil {
      try ValidationError.shouldntExist(args.inputLanguage, "from")
      try ValidationError.shouldntExist(args.inputLocation, "input-location")
      try ValidationError.shouldntExist(args.langInOpts, "lang-in-opt")
      try ValidationError.shouldntExist(args.attributes, "attribute")
      try ValidationError.shouldntExist(args.outputLanguage, "to")
      try ValidationError.shouldntExist(args.outputLocation, "output")
      try ValidationError.shouldntExist(args.langOutOpts, "to")
      try ValidationError.shouldntExist(args.outputLibraryName, "lib-name")
      try ValidationError.shouldntExist(args.link, "link")
      try ValidationError.shouldntExist(args.indentType, "indent-type")
      try ValidationError.shouldntExist(args.indentCount, "indent-count")
    } else {
      try ValidationError.shouldExist(args.inputLanguage, "from")
      try ValidationError.shouldExist(args.inputLocation, "input-location")
      try ValidationError.shouldExist(args.outputLanguage, "to")
      try ValidationError.shouldExist(args.outputLocation, "output-location")
      try ValidationError.shouldExist(args.outputLibraryName, "lib-name")
    }
  }
}
