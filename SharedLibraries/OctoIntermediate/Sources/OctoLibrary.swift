//import Logging
import OctoIO

// TODO: ~Copyable when migrating too Swift 6
public struct OctoLibrary: AutoRemovable {
  static let logger = Logger(label: "be.jonaseveraert.Octo.OctoIntermediate")

  public var ffiLanguage: Language = .c
  private var langRefMap: [AnyHashable:Int] = [:]
  private var nameMap: [String:Int] = [:]
  public private(set) var typedefs: [String:OctoType] = [:]
  public private(set) var objects: [OctoObject] = []
  public var destroy: () -> Void = {}
  private var hasFinalized = false

  //public var objectInclude: (OctoObject) -> Bool = { (object: OctoObject) in true }
  // TODO: provide includes for C?

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
      #if OCTO_DEBUGINFO
      Self.logger.trace("Couldn't find object for ref \(ref) in \(self.langRefMap) \(self.langRefMap.map { (k,_) in k == ref })")
      #endif
      return nil
    }
    return self.objects[id]
  }

  public func getObject(byName name: String) -> OctoObject? {
    if let typedefType = self.typedefs[name] {
      switch (typedefType.kind) {
        case .Record(let record): return record
        case .Enum(let e): return e
        default:
          Self.logger.warning("Found \(typedefType) for typedef \(name), continuing to search for object named \(name)")
      }
    }

    guard let id = self.nameMap[name] else {
      return nil
    }
    return self.objects[id]
  }

  public func getObjectHash(byName name: String, ofType type: OctoObject.Type) -> AnyHashable? {
    guard let id = self.nameMap[name] else {
      return nil
    }

    if Swift.type(of: self.objects[id]) != type {
      return nil
    }

    return langRefMap.first(where: { (hash, objId) in objId == id })?.key
  }

  /// Get the underlying type of a typedef
  public func getType(byName name: String) -> OctoType? {
    if let typedefType = self.typedefs[name] {
      return typedefType
    }

    guard let id = self.nameMap[name] else {
      return nil
    }
    let obj = self.objects[id]
    if let obj = obj as? OctoEnum {
      return OctoType(kind: .Enum(obj), optional: false, mutable: true)
    } else if let obj = obj as? OctoRecord {
      return OctoType(kind: .Record(obj), optional: false, mutable: true)
    } else {
      fatalError("bug")
    }
  }

  enum AddTypedefError: Error {
    case typeNotFound(ref: AnyHashable)
    case typeNotTypedefCapable(obj: OctoObject)
  }

  public mutating func addTypedef(toRef ref: AnyHashable, name: String) throws {
    if let obj = self.getObject(forRef: ref) {
      try self.addTypedef(toObject: obj, name: name)
    } else {
      throw AddTypedefError.typeNotFound(ref: ref)
    }
  }

  public mutating func addTypedef(toObject object: OctoObject, name: String) throws {
    if let obj = object as? OctoRecord {
      self.addTypedef(toType: OctoType(kind: .Record(obj), optional: false, mutable: true), name: name)
    } else if let obj = object as? OctoEnum {
      self.addTypedef(toType: OctoType(kind: .Enum(obj), optional: false, mutable: true), name: name)
    } else {
      throw AddTypedefError.typeNotTypedefCapable(obj: object)
    }
  }

  public mutating func addTypedef(toType type: OctoType, name: String) {
    if let existingType = self.typedefs[name] {
      Self.logger.warning("Typedef with name \(name) already exists for type \(existingType), redefinition will override the current definition with \(type)")
    }
    self.typedefs[name] = type
  }

  //public mutating func addTypedefListener(toTypeResolver: @escaping (OctoLibrary) -> OctoType?, name: String) {
  //  self.deferredTypedefResolutions.append((name, toTypeResolver))
  //}

  public func renameObjects(_ renameOp: (String) throws -> String) rethrows {
    for object in self.objects {
      if let bindingName = object.bindingName {
        object.rename(to: try renameOp(bindingName))
      }
    }
  }

  public mutating func finalize() throws {
    if self.hasFinalized { return }
    let sortOrder = { (obj: OctoObject) in
      if obj is OctoTypedef { return 1 }
      if obj is OctoField || obj is OctoArgument || obj is OctoEnumCase { return 2 }
      if obj is OctoRecord || obj is OctoEnum { return 3 }
      if obj is OctoFunction { return 4 }
      return 5
    }
    for obj in self.objects.sorted(by: { (a, b) in sortOrder(a) < sortOrder(b) }) {
      try obj.finalize(self)
    }
    self.hasFinalized = true
  }
}

extension OctoLibrary: CustomDebugStringConvertible {
  public var debugDescription: String {
    var msg = """
    OctoLibrary:
      ffiLanguage = \(self.ffiLanguage)
    \(self.objects.enumerated().filter { (_, obj) in !(obj is OctoField || obj is OctoEnumCase || obj is OctoArgument) }.map { (i, obj) in
      String(reflecting: obj)
    }.joined(separator: "\n"))
    """
    #if OCTO_DEBUGINFO
    msg += "\n" + self.langRefMap.map { (k, v) in
      let obj = self.objects[v]
      return "\(k.hashValue): \(obj.ffiName ?? "\(obj)")"
    }.joined(separator: "\n")
    #endif
    return msg
  }
}
