import OctoIO

public enum LogLevel: UInt8 {
  case debug
  case info
  case warning
  case error
}

var LOG_LEVEL: LogLevel = .warning

public func setOctoLogLevel(_ logLevel: LogLevel) {
  LOG_LEVEL = logLevel
}

func log(_ msg: String, _ logLevel: LogLevel = .info) {
  if logLevel.rawValue >= LOG_LEVEL.rawValue {
    // TODO: formatting based on log level, origin
    print(msg, to: .stderr)
  }
}
