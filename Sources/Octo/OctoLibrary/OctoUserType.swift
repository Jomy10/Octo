import Foundation

public struct OctoUserType: OctoObject {
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
}

extension OctoUserType: Equatable {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}
