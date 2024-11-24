import OctoIO
import Puppy
import Logging

func setupTestLogger(_ ctx: String) {
  let logFormat = OctoLogFormatter()
  let consoleLogger = ConsoleLogger(ctx, logFormat: logFormat)
  var puppy = Puppy()
  puppy.add(consoleLogger)
  LoggingSystem.bootstrap {
    var handler = PuppyLogHandler(label: $0, puppy: puppy)
    handler.logLevel = .debug
    return handler
  }
}
