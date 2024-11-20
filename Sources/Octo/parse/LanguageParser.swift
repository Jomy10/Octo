import ExpressionInterpreter
import OctoIO

public struct LanguageParser {
  public static func parse(language: Language, config: ParseConfiguration) throws -> OctoLibrary {
    let executor = Executor()
    var lib: OctoLibrary
    switch (language) {
      case .c:
        lib = try Self.parseC(config: config)
      default:
        octoLogger.fatal("Unimplemented language \(language)")
    }

    // TODO: why are structs generated twice? (once without attached functions, once with)
    try lib.renameObjects { (name: String) throws -> String in
      let newName: String = try config.renameOperations.reduce(into: name, { (currentName: inout String, renameOperation: Program) throws -> () in
        executor.setVar(name: "name", value: .string(value: currentName))
        let newNameValue = try executor.execute(program: renameOperation)
        //if newNameResult.isError {
        //  throw ParseError("while executing rename operation \"\(renameOperation)\": rename operation threw an execution error: \(newNameResult.error)")
        //}
        if case .string(value: let newName) = newNameValue {
          currentName = newName
        } else {
          throw ParseError("while executing rename operation \"\(renameOperation)\": rename operation program doesn't return 'String' (got: \(newNameValue))")
        }
      })
      return newName
    }
    //for obj in (lib.iterObjects()
    //  .map { objid in lib.getObject(id: objid)! }
    //  .filter { obj in obj.isRenamable }
    //  .map { obj in obj as! (OctoObject & OctoRenamable) }
    //) {
    //  executor.addVariable(name: "name", value: obj.bindingName)
    //  for renameOperation in config.renameOperations {
    //    let newNameValue = executor.execute(program: renameOperation)
    //    if case .string(let newName) = newNameValue {
    //      obj.rename(to: newName)
    //    } else {
    //      throw ParseError("while executing rename operation \"\(renameOperation)\": rename operation program doesn't return 'String' (got: \(newNameValue))")
    //    }
    //    // TODO: get string value from return value and rename the variable
    //  }
    //}

    return lib
  }
}
