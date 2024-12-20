import OctoIO
import OctoParse
import OctoGenerate
import OctoGenerateShared
import ArgumentParser

extension OctoGenerate {
  func parseConfig() throws -> OctoConfig {
    if let configFile = self.configFileArg.configFile {
      return try OctoConfig(decodingTOMLFile: configFile)
    } else {
      return try OctoConfig(fromArguments: self.configArgs)
    }
  }

  mutating func run() throws {
    let config = try self.parseConfig()

    // Setup logging
    let logFormat = OctoLogFormatter()
    let consoleLogger = ConsoleLogger("be.jonaseveraert.Octo", logFormat: logFormat)
    var puppy = Puppy()
    puppy.add(consoleLogger)
    let verbosityLevel = self.verbosityLevel
    LoggingSystem.bootstrap {
      var handler = PuppyLogHandler(label: $0, puppy: puppy)
      switch (verbosityLevel) {
        case 0: handler.logLevel = .warning
        case 1: handler.logLevel = .info
        case 2: handler.logLevel = .debug
        default: // 3 or more
          handler.logLevel = .trace
      }
      return handler
    }

    let parseConfig = ParseConfiguration(
      languageSpecificConfig: config.langInOpts,
      renameOperations: config.renameOperations
    )
    let lib = try OctoParser.parse(
      language: config.inputLanguage,
      config: parseConfig,
      input: config.inputLocation
    )

    // Add attributes
    for attribute in config.attributes {
      let octoAttribute = try attribute.toOctoAttribute(in: lib.inner)
      guard let object = lib.inner.getObject(byName: attribute.symbolName) else {
        throw Attribute.AttributeError("Symbol \(attribute.symbolName) not found in library")
      }
      try object.addAttribute(octoAttribute)
    }

    // Generate
    for (lang, oconfig) in config.outputOptions {

      let genOptions = GenerationOptions(
        moduleName: config.outputLibraryName,
        indent: String(repeating: oconfig.indentType.stringValue, count: oconfig.indentCount),
        libs: config.link,
        languageSpecificOptions: oconfig.langOutOpts
      )
      let code = try OctoGenerator.generate(
        language: lang,
        lib: &lib.inner,
        options: genOptions
      )
      try code.write(to: oconfig.outputLocation)
    }
  }
}
