import Foundation

struct OctoEnum {
  let type: OctoType
  let name: String
  let origin: OctoOrigin
  var cases: [UUID] = []
  var methods: [UUID] = []
  var staticMethods: [UUID] = []

  var bindingName: String {
    self.name
  }

  mutating func addCase(_ id: UUID) {
    self.cases.append(id)
  }

  mutating func attachFunction(_ fnId: UUID, type: OctoFunctionType) {
    switch (type) {
      case .method:
        self.methods.append(fnId)
      case .staticMethod:
        self.staticMethods.append(fnId)
      default:
        fatalError("[\(self.origin)] ERROR: Enums can't have attached functions of type \(type)")
    }
  }
}

struct OctoEnumCase: OctoObject {
  let id = UUID()

  let name: String
  let value: Value
  let origin: OctoOrigin

  var bindingName: String {
    self.name
  }

  enum Value {
    case signed(Int64)
    case unsigned(UInt64)
  }
}

extension OctoEnumCase.Value {
  var stringValue: String {
    switch (self) {
      case .signed(let s): return "\(s)"
      case .unsigned(let u): return "\(u)"
    }
  }
}
