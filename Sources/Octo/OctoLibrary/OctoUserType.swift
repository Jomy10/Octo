import Foundation

struct OctoUserType: OctoObject {
  let id: UUID = UUID()

  var inner: Self.Data
    
  var origin: OctoOrigin {
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
