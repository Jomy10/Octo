//import Logging
import OctoIO

// TODO: ~Copyable when migrating too Swift 6
public struct OctoLibrary: AutoRemovable {
  static let logger = Logger(label: "be.jonaseveraert.Octo.OctoIntermediate")

  public var ffiLanguage: Language = .c
  private var langRefMap: [AnyHashable:Int] = [:]
  private var nameMap: [String:Int] = [:]
  public private(set) var objects: [OctoObject] = []
  public var destroy: () -> Void = {}
  private var hasFinalized = false

  public init() {}

  enum AddObjectError: Error {
    case objectExists(ref: AnyHashable, obj: OctoObject)
  }

  public mutating func addObject(_ obj: OctoObject, ref: AnyHashable) throws {
    if self.langRefMap[ref] != nil {
      throw AddObjectError.objectExists(ref: ref, obj: obj)
    }
    if obj is OctoRecord || obj is OctoEnum || obj is OctoFunction || obj is OctoTypedef {
      if self.nameMap[obj.ffiName!] != nil {
        if !(obj is OctoTypedef) {
          OctoLibrary.logger.warning("Object \(obj.ffiName!) already exists, overriding name definition. This might lead to unexpected behaviour")
        }
      } else {
        self.nameMap[obj.ffiName!] = self.objects.count
      }
    }
    self.langRefMap[ref] = self.objects.count
    self.objects.append(obj)
  }

  public func getObject(forRef ref: AnyHashable) -> OctoObject? {
    guard let id = self.langRefMap[ref] else {
      return nil
    }
    return self.objects[id]
  }

  public func getObject(byName name: String) -> OctoObject? {
    guard let id = self.nameMap[name] else {
      return nil
    }
    return self.objects[id]
  }

  public func renameObjects(_ renameOp: (String) throws -> String) rethrows {
    for object in self.objects {
      if let bindingName = object.bindingName {
        object.rename(to: try renameOp(bindingName))
      }
    }
  }

  public mutating func finalize() throws {
    if self.hasFinalized { return }
    for obj in self.objects {
      try obj.finalize()
    }
    self.hasFinalized = true
  }
}
