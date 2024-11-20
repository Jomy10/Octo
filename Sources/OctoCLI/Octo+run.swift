import Foundation
import Octo
import OctoIO
import Logging
import Puppy
import ColorizeSwift

struct OctoLogFormatter: LogFormattable {
  public func formatMessage(
    _ level: LogLevel,
    message: String,
    tag: String,
    function: String,
    file: String,
    line: UInt,
    swiftLogInfo: [String:String],
    label: String,
    date: Date,
    threadID: UInt64
  ) -> String {
    //print(level, message, tag, function, file, line, swiftLogInfo, label, date, threadID)
    // label: "\(label).\(swiftLogInfo["source"])"
    var levelString = "\(level)"
    switch (level) {
    case .verbose: fallthrough
    case .trace: fallthrough
    case .debug: fallthrough
    case .info:
      break
    case .notice:
      levelString = levelString.lightBlue()
    case .warning:
      levelString = levelString.yellow()
    case .error:
      levelString = levelString.lightRed()
    case .critical:
      levelString = levelString.red().bold()
    }

    var message: String = "[\(levelString)] \(message)"
    if let origin = swiftLogInfo["metadata"] {
      message += " @ \(origin)"
    }
    return message
  }
}

extension Octo {
  mutating func run() throws {
    try self.initArgs()

    //if self.verbose {
    //  setOctoLogLevel(.info)
    //}
    //if self.veryVerbose {
    //  setOctoLogLevel(.debug)
    //}

    // Setup logging
    let logFormat = OctoLogFormatter()
    let consoleLogger = ConsoleLogger("be.jonaseveraert.Octo", logFormat: logFormat)
    var puppy = Puppy()
    puppy.add(consoleLogger)

    let logLevel = self.verboseLevel
    LoggingSystem.bootstrap {
      var handler = PuppyLogHandler(label: $0, puppy: puppy)
      switch (logLevel) {
        case 0: handler.logLevel = .warning
        case 1: handler.logLevel = .info
        case 2: handler.logLevel = .debug
        default:
         handler.logLevel = .trace
      }
      return handler
    }

    // Parse //
    let languageSpecificConfig: ParseConfiguration.LanguageSpecificConfiguration
    switch (self.args.inputLanguage) {
      case .c:
        languageSpecificConfig = .c(ParseConfiguration.CConfig(
          headerFile: self.args.inputLocation,
          clangFlags: self.args.cIn_clangFlags,
          includeHeaders: self.args.cIn_includeHeaders,
          logLevel: self.args.cIn_logLevel ?? .note,
          errorLevel: self.args.cIn_errorLevel ?? .error
        ))
      default:
        fatalError("Parsing of language \(self.args.inputLanguage) is not yet supported")
    }
    let parseConfig = ParseConfiguration(
      outputLibraryName: self.args.outputLibraryName,
      renameOperations: self.args.renameOperations,
      //outputLocation: self.args.outputLocation,
      languageSpecificConfig: languageSpecificConfig
    )

    var library = try LanguageParser.parse(language: self.args.inputLanguage, config: parseConfig)
    defer { library.destroy() }

    let attributesEnumerated: EnumeratedSequence<[Attribute]> = self.args.attributes.enumerated()
    for (i, attribute) in attributesEnumerated {
      guard let objectId = library.getObject(name: String(attribute.symbolName)) else {
        // TODO: replace with throw
        fatalError("Symbol '\(attribute.symbolName)' doesn't exist (passed as argument to --argument)")
      }
      library.addAttribute(to: objectId, attribute.asOctoAttribute, id: OctoLibrary.LangId.arg(i))
    }

    // Generate code //
    for (language, args) in self.args.outputOptions {
      let generationOptions = GenerationOptions(
        indent: args.indent,
        libs: self.args.linkLibs
      )
      let code = try CodeGenerator.generate(language: language, lib: library, options: generationOptions)

      try code.write(to: args.outputLocation)
    }
  }
}
