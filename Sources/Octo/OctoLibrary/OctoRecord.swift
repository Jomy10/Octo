import Foundation

struct OctoRecord {
  let name: String
  let origin: OctoOrigin
  let type: RecordType
  var fields: [UUID] = []

  var initializers: [UUID] = []
  var deinitializer: UUID? = nil
  var methods: [UUID] = []
  var staticMethods: [UUID] = []

  var bindingName: String {
    self.name
  }

  enum RecordType {
    case `struct`
    case `union`
  }

  mutating func addField(_ fieldId: UUID) {
    self.fields.append(fieldId)
  }

  mutating func attachFunction(_ fnId: UUID, type: OctoFunctionType) {
    switch (type) {
      case .`init`: self.initializers.append(fnId)
      case .`deinit`:
        if self.deinitializer != nil {
          fatalError("ERROR: cannot specify multiple deinitializers for \(self.name)")
        }
        self.deinitializer = fnId
      case .method: self.methods.append(fnId)
      case .staticMethod: self.staticMethods.append(fnId)
      case .function:
        fatalError("Cannot attach function of type 'function' to record")
    }
  }
}

struct OctoField: OctoObject {
  let id = UUID()

  var type: OctoType
  let name: String
  let origin: OctoOrigin
  var fields: [UUID] = []
  var visible = true

  var nullable: Bool {
    get { self.type.nullable }
    set {
      self.type.nullable = newValue
    }
  }

  mutating func addField(_ id: UUID) {
    self.fields.append(id)
  }
}
