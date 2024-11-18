import Foundation

public struct OctoUserType: OctoObject, OctoRenamable {
  public let id: UUID = UUID()

  var inner: Self.Data

  public var origin: OctoOrigin {
    switch (self.inner) {
      case .record(let record): return record.origin
      case .enum(let e): return e.origin
    }
  }

  enum Data {
    case `record`(OctoRecord)
    case `enum`(OctoEnum)
  }

  public mutating func rename(to newName: String) {
    switch (self.inner) {
      case .record(var record):
        record.rename(to: newName)
        self.inner = .record(record)
      case .enum(var e):
        e.rename(to: newName)
        self.inner = .enum(e)
    }
  }

  public var bindingName: String {
    switch (self.inner) {
      case .record(let record): return record.bindingName
      case .enum(let e): return e.bindingName
    }
  }
}

extension OctoUserType: Equatable {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}
