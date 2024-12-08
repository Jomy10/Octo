import Foundation
import Puppy
import ColorizeSwift

public struct OctoLogFormatter: LogFormattable {
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

  public init() {}
}
