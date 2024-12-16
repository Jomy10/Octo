import OctoIO

// Function //

public final class OctoFunction: OctoObject {
  public private(set) var arguments: [OctoArgument]
  public private(set) var returnType: OctoType
  public private(set) var kind: FunctionType
  public private(set) var attachedTo: (any OctoFunctionAttachable)?
  /// Should only be accessed after parsing
  public private(set) var selfArgumentIndex: Int? = nil
  public private(set) var initializerType: InitializerType = .none

  public enum InitializerType {
    // void init(Self*);
    case selfArgument
    /// Self* init(); or Self init();
    case returnsSelf
    case none
  }

  public enum FunctionType: Equatable {
    case initializer
    case deinitializer
    case method
    case staticMethod
    case function

    init?(fromArgument arg: String) {
      switch (arg) {
        case "init": self = .initializer
        case "deinit": self = .deinitializer
        case "method": self = .method
        case "staticMethod": self = .staticMethod
        default: return nil
      }
    }
  }

  public init(
    origin: OctoOrigin,
    name: String,
    returnType: OctoType,
    arguments: [OctoArgument] = [],
    kind: FunctionType = .function,
    attachedTo: (any OctoFunctionAttachable)? = nil
  ) {
    self.returnType = returnType
    self.arguments = arguments
    self.kind = kind
    self.attachedTo = attachedTo
    self.selfArgumentIndex = nil
    super.init(origin: origin, name: name)
  }

  public var selfArgument: OctoArgument? {
    if let index = self.selfArgumentIndex {
      return self.arguments[index]
    } else {
      return nil
    }
  }

  public var hasSelfArgument: Bool {
    self.selfArgumentIndex != nil
  }

  public var hasUserTypeArgument: Bool {
    self.arguments.firstIndex(where: { arg in arg.type.isUserType }) != nil
  }

  public func addArgument(_ arg: OctoArgument) {
    self.arguments.append(arg)
  }

  public override func attach(to object: any OctoFunctionAttachable, kind: FunctionType = .method) throws /* FunctionAttachError */ {
    if self.kind != .function {
      throw FunctionAttachError.functionAlreadyAttached(function: self, attachedTo: object)
    }

    self.attachedTo = object
    self.kind = kind

    try object.attachFunction(self)
  }

  public override func setReturnsNonNull(_ val: Bool) throws {
    self.returnType.optional = false
  }

  override func finalize(_ lib: OctoLibrary) throws {
    guard let object = self.attachedTo else {
      return
    }

    let isSelfTypeObject: (OctoType, OctoObject) -> Bool = { (type: OctoType, selfTypeObject: OctoObject) -> Bool in
      switch (type.kind) {
        case .Record(let record): return selfTypeObject == record
        case .Enum(let e): return selfTypeObject == e
        case .Pointer(let ptype):
          switch (ptype.kind) {
            case .Record(let record): return selfTypeObject == record
            case .Enum(let e): return selfTypeObject == e
            default: return false //throw FunctionAttachError.initializerTypeMismatch(function: self, attachedTo: object)
          }
        default: return false //throw FunctionAttachError.initializerTypeMismatch(function: self, attachedTo: object)
      }
    }

    if self.kind == .method || self.kind == .deinitializer {
      if let selfArgumentIndex = self.arguments.firstIndex(where: { arg in isSelfTypeObject(arg.type, object) }) {
        self.arguments[selfArgumentIndex].isSelfArgument = true
        self.selfArgumentIndex = selfArgumentIndex
      } else {
        //throw FunctionAttachError.noSelfArgument(function: self)
        OctoLibrary.logger.warning("Function \(self.ffiName!) has no `self` parameter of type \(object.ffiName!)")
        OctoLibrary.logger.debug("\(self.ffiName!) args: \(self.arguments.count)\n\(self.arguments.map({ arg in "arg: type = \(arg.type)"}).joined(separator: "\n"))")
      }
    } else if self.kind == .initializer {
      if !isSelfTypeObject(self.returnType, object) {
      // TODO: first get pointeeType, then pass t isSelfTypeObject
        if let selfArgumentIndex = self.arguments.firstIndex(where: { arg in isSelfTypeObject(arg.type, object) }) {
          self.arguments[selfArgumentIndex].isSelfArgument = true
          self.selfArgumentIndex = selfArgumentIndex
          self.initializerType = .selfArgument
        } else {
          throw FunctionAttachError.initializerTypeMismatch(function: self, attachedTo: object)
        }
      } else {
        self.initializerType = .returnsSelf
      }
    }

    self.returnType.finalize(lib)
    try super.finalize(lib)
  }
}

// Argument //

public final class OctoArgument: OctoObject {
  public private(set) var type: OctoType
  // TODO
  //public let defaultValue: Value?
  public private(set) var namedArgument: Bool
  public internal(set) var isSelfArgument: Bool

  public init(
    origin: OctoOrigin,
    name: String?,
    type: OctoType,
    namedArgument: Bool = false,
    isSelfArgument: Bool = false
  ) {
    self.type = type
    self.namedArgument = namedArgument
    self.isSelfArgument = isSelfArgument
    super.init(origin: origin, name: name)
  }

  public override func setNullable(_ val: Bool) throws {
    self.type.optional = val
  }

  override func finalize(_ lib: OctoLibrary) throws {
    self.type.finalize(lib)
    try super.finalize(lib)
  }
}

// FunctionAttachable //

enum FunctionAttachError: Error {
  case deinitializerAlreadyExists(target: any OctoFunctionAttachable)
  case invalidFunctionType(type: OctoFunction.FunctionType)
  case functionAlreadyAttached(function: OctoFunction, attachedTo: any OctoFunctionAttachable)
  //case noSelfArgument(function: OctoFunction)
  case initializerTypeMismatch(function: OctoFunction, attachedTo: OctoObject)
}

extension FunctionAttachError: CustomStringConvertible {
  var description: String {
    """
    FunctionAttachError: \({switch (self) {
      case .deinitializerAlreadyExists(target: let target):
        return "Deinitializer specified twice on target \(target)"
      case .invalidFunctionType(type: let type):
        return "Function of type \(type) cannot be attached"
      case .functionAlreadyAttached(function: let function, attachedTo: let object):
        return "Function \(function.ffiName ?? "unnamed") is already attached to \(function.attachedTo!) (while trying to attach to \(object))"
      //case .noSelfArgument(function: let function):
      //  return "Found no `self` argument for '\(function.ffiName!)' @ \(function.origin)"
      case .initializerTypeMismatch(function: let function, attachedTo: let attachedTo):
        return "Initializer \(function.ffiName!) does not return \(attachedTo.ffiName!)"
    }}())
    """
  }
}

public protocol OctoFunctionAttachable: OctoObject {
  var initializers: [OctoFunction] { get set }
  var deinitializer: OctoFunction? { get set }
  var methods: [OctoFunction] { get set }
  var staticMethods: [OctoFunction] { get set }

  func attachFunction(_ fn: OctoFunction) throws
}

extension OctoFunctionAttachable {
  public func attachFunction(_ fn: OctoFunction) throws /*OctoFunctionAttachError*/ {
    switch (fn.kind) {
      case .initializer:
        self.initializers.append(fn)
      case .deinitializer:
        if self.deinitializer != nil {
          throw FunctionAttachError.deinitializerAlreadyExists(target: self)
        }
        self.deinitializer = fn
      case .method:
        self.methods.append(fn)
      case .staticMethod:
        self.staticMethods.append(fn)
      case .function:
        throw FunctionAttachError.invalidFunctionType(type: fn.kind)
    }
  }
}

// Calling Convention //
public enum OctoCallingConv {
  case c
  case swift
}

// String //

extension OctoFunction: CustomDebugStringConvertible {
  public var debugDescription: String {
    var msg = "@Function \(self.bindingName!) ->\(self.returnType) attach:\(self.attachedTo == nil ? "nil" : "\(self.attachedTo!)"))"
    for arg in self.arguments {
      msg += "\n  \(String(reflecting: arg))"
    }
    return msg
  }
}

extension OctoArgument: CustomDebugStringConvertible {
  public var debugDescription: String {
    "@Argument \(String(describing: self.bindingName)) \(self.type) self:\(self.isSelfArgument) named:\(self.namedArgument)"
  }
}
