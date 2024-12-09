import Foundation
@_exported import Logging
@_exported import Puppy

public protocol IntoMetadataValue {
  func into() -> Logger.MetadataValue
}

extension Logger {
  public func trace(
    _ message: @autoclosure () -> Logger.Message,
    origin: some IntoMetadataValue
  ) {
    self.trace(message(), metadata: ["origin": origin.into()])
  }

  public func debug(
    _ message: @autoclosure () -> Logger.Message,
    origin: some IntoMetadataValue
  ) {
    self.debug(message(), metadata: ["origin": origin.into()])
  }

  public func info(
    _ message: @autoclosure () -> Logger.Message,
    origin: some IntoMetadataValue
  ) {
    self.info(message(), metadata: ["origin": origin.into()])
  }

  public func notice(
    _ message: @autoclosure () -> Logger.Message,
    origin: some IntoMetadataValue
  ) {
    self.notice(message(), metadata: ["origin": origin.into()])
  }

  public func warning(
    _ message: @autoclosure () -> Logger.Message,
    origin: some IntoMetadataValue
  ) {
    self.warning(message(), metadata: ["origin": origin.into()])
  }

  public func error(
    _ message: @autoclosure () -> Logger.Message,
    origin: some IntoMetadataValue
  ) {
    self.error(message(), metadata: ["origin": origin.into()])
  }

  public func critical(
    _ message: @autoclosure () -> Logger.Message,
    origin: some IntoMetadataValue
  ) {
    self.critical(message(), metadata: ["origin": origin.into()])
  }

  public func fatal(
    _ message: @autoclosure () -> Logger.Message,
    metadata: @autoclosure () -> Logger.Metadata? = nil,
    source: @autoclosure () -> String? = nil,
    file: String = #fileID, function: String = #function, line: UInt = #line
  ) -> Never {
    self.error(message(), metadata: metadata(), source: source(), file: file, function: function, line: line)
    exit(1)
  }

  public func fatal(
    _ message: @autoclosure () -> Logger.Message,
    origin: some IntoMetadataValue
  ) -> Never {
    self.fatal(message(), metadata: ["origin": origin.into()])
  }
}

@available(*, deprecated, message: "Create a new logger for each package instead")
public let octoLogger: Logger = Logger(label: "be.jonaseveraert.Octo")

//public enum LogLevel: UInt8 {
//  case debug
//  case info
//  case warning
//  case error
//}

//var LOG_LEVEL: LogLevel = .warning

//public func setOctoLogLevel(_ logLevel: LogLevel) {
//  LOG_LEVEL = logLevel
//}

//public func log(_ msg: String, _ logLevel: LogLevel = .info) {
//  if logLevel.rawValue >= LOG_LEVEL.rawValue {
//    // TODO: formatting based on log level, origin
//    print(msg, to: .stderr)
//  }
//}
