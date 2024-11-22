// Function //

public final class OctoFunction: OctoObject {
  public private(set) var arguments: [OctoArgument]
  public private(set) var returnType: OctoType
  public private(set) var kind: FunctionType
  public private(set) var attachedTo: (any OctoFunctionAttachable)?

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
    super.init(origin: origin, name: name)
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
}

// Argument //

public final class OctoArgument: OctoObject {
  public private(set) var type: OctoType
  // TODO
  //public let defaultValue: Value?
  public private(set) var namedArgument: Bool

  public init(
    origin: OctoOrigin,
    name: String?,
    type: OctoType
  ) {
    self.type = type
    self.namedArgument = name != nil
    super.init(origin: origin, name: name)
  }

  public override func setNullable(_ val: Bool) throws {
    self.type.optional = val
  }
}

// FunctionAttachable //

enum FunctionAttachError: Error {
  case deinitializerAlreadyExists(target: any OctoFunctionAttachable)
  case invalidFunctionType(type: OctoFunction.FunctionType)
  case functionAlreadyAttached(function: OctoFunction, attachedTo: any OctoFunctionAttachable)
}

extension FunctionAttachError: CustomStringConvertible {
  var description: String {
    switch (self) {
      case .deinitializerAlreadyExists(target: let target):
        return "Deinitializer specified twice on target \(target)"
      case .invalidFunctionType(type: let type):
        return "Function of type \(type) cannot be attached"
      case .functionAlreadyAttached(function: let function, attachedTo: let object):
        return "Function \(function.ffiName ?? "unnamed") is already attached to \(function.attachedTo!) (while trying to attach to \(object))"
    }
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
