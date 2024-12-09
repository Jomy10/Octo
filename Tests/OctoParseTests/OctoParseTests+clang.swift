import XCTest
@testable import OctoParse
import OctoIntermediate
import PluginManager

func intoSubstringArray(_ arr: [[String]]) -> [[Substring]] {
  arr.map { innerArr in
    innerArr.map { inner in
      inner[inner.startIndex..<inner.endIndex]
    }
  }
}

struct TestError: Error {
  let message: String
}

final class OctoParseTests_Clang: XCTestCase {
  func loadConfig() throws -> ParseConfiguration {
    let plugin = try PluginManager.default.getParserPlugin(languageName: "C")
    let args = [
      ["logLevel", "ignored"],
      ["errorLevel", "warning"]
    ]

    var langConfig: UnsafeMutableRawPointer? = nil
    let errorMessage = plugin.parseConfigForArguments(intoSubstringArray(args), &langConfig)
    //let error = withUnsafePointer(to: intoSubstringArray(args)) { argsPtr in
    //  plugin.parser_parseConfigForArguments.function(UnsafeRawPointer(argsPtr), &langConfig)
    //}
    if let errorMessage = errorMessage {
      throw TestError(message: errorMessage)
    }

    return ParseConfiguration(
      languageSpecificConfig: langConfig!,
      renameOperations: []
    )
  }
  //let config = ParseConfiguration(
  //  languageSpecificConfig: .c(ParseConfiguration.CConfig(
  //    clangFlags: [],
  //    includeHeaders: [],
  //    logLevel: .ignored,
  //    errorLevel: .warning
  //  )),
  //  renameOperations: []
  //)

  func testParseRecord() throws {
    let config = try self.loadConfig()
    let lib = try OctoParser.parse(language: .c, config: config, input: URL(filePath: "./Tests/OctoParseTests/testParseRecord.h", directoryHint: .notDirectory, relativeTo: URL.currentDirectory()))

    for obj in lib.inner.objects {
      if let obj = obj as? OctoRecord {
        XCTAssertEqual(obj.ffiName, "MyStruct")
        XCTAssertEqual(obj.bindingName, "Adder")
        XCTAssertEqual(obj.type, OctoRecord.RecordType.`struct`)

        XCTAssertEqual(obj.fields.count, 2)
        XCTAssertEqual(obj.fields[0].ffiName, "a")
        XCTAssertEqual(obj.fields[1].ffiName, "b")
        XCTAssertEqual(obj.fields[0].bindingName, "lhs")
        XCTAssertEqual(obj.fields[1].bindingName, "rhs")
        XCTAssert(obj.fields[0].type.kind.isSignedInt ?? false)
        XCTAssert(obj.fields[1].type.kind.isSignedInt ?? false)

        XCTAssertEqual(obj.initializers.count, 1)
        XCTAssertEqual(obj.initializers[0].returnType, OctoType(
          kind: OctoType.Kind.Pointer(to: OctoType(
            kind: OctoType.Kind.Record(obj),
            optional: false,
            mutable: false
          )),
          optional: false,
          mutable: true
        ))
        XCTAssertEqual(obj.initializers[0].kind, OctoFunction.FunctionType.initializer)
        XCTAssertEqual((obj.initializers[0].attachedTo! as! OctoRecord), obj)
        XCTAssertEqual(obj.initializers[0].arguments.count, 0)

        XCTAssertEqual(obj.deinitializer?.arguments.count, 1)
        XCTAssertEqual(obj.deinitializer?.arguments[0].type, OctoType(
          kind: OctoType.Kind.Pointer(to: OctoType(
            kind: OctoType.Kind.Record(obj),
            optional: false,
            mutable: true
          )),
          optional: true,
          mutable: true
        ))
        XCTAssertEqual(obj.deinitializer?.returnType.kind, .Void)

        XCTAssertEqual(obj.staticMethods.count, 0)

        XCTAssertEqual(obj.methods.count, 1)
        XCTAssertEqual(obj.methods[0].ffiName, "Adder_add")
        XCTAssertEqual(obj.methods[0].bindingName, "add")
        XCTAssertEqual(obj.methods[0].returnType, OctoType(
          kind: .I32,
          optional: false,
          mutable: true
        ))
        XCTAssertEqual(obj.methods[0].kind, OctoFunction.FunctionType.method)
        XCTAssertEqual(obj.methods[0].attachedTo! as! OctoRecord, obj)
        XCTAssertEqual(obj.methods[0].arguments.count, 1)
        XCTAssertEqual(obj.methods[0].arguments[0].ffiName, nil)
        XCTAssertEqual(obj.methods[0].arguments[0].bindingName, nil)
        XCTAssertEqual(obj.methods[0].arguments[0].namedArgument, false)
        XCTAssertEqual(obj.methods[0].arguments[0].type, OctoType(
          kind: OctoType.Kind.Pointer(to: OctoType(
            kind: OctoType.Kind.Record(obj),
            optional: false,
            mutable: false
          )),
          optional: false,
          mutable: true
        ))
      } // TODO: no other functions or objects which would generate binding code
      else if let obj = obj as? OctoFunction {
        if obj.kind == .function {
          XCTFail("Unexpected function \(obj)")
        }
      } else if let obj = obj as? OctoEnum {
        XCTFail("Unexpected enum \(obj)")
      }
    }
  }

  func testParseEnum() throws {
    let config = try self.loadConfig()
    let lib = try OctoParser.parse(language: .c, config: config, input: URL(filePath: "./Tests/OctoParseTests/testParseEnum.h", directoryHint: .notDirectory, relativeTo: URL.currentDirectory()))

    if !(lib.inner.objects.contains(where: {$0 is OctoEnum})) {
      XCTFail("No enum was created")
    }

    var enumObj: OctoEnum? = nil
    for obj in lib.inner.objects {
      if let obj = obj as? OctoEnum {
        enumObj = obj
        XCTAssertEqual(obj.ffiName, "MyEnum")
        XCTAssertEqual(obj.bindingName, "MyEnum")
        XCTAssertEqual(obj.type, OctoType(
          kind: .I32,
          optional: false,
          mutable: false
        ))

        XCTAssertEqual(obj.cases.count, 3)
        XCTAssertEqual(obj.cases[0].ffiName, "A")
        XCTAssertEqual(obj.cases[1].ffiName, "B")
        XCTAssertEqual(obj.cases[2].ffiName, "C")
        XCTAssertEqual(obj.cases[0].value, .int(-1))
        XCTAssertEqual(obj.cases[1].value, .int(0))
        XCTAssertEqual(obj.cases[2].value, .int(5))
      } else if let obj = obj as? OctoFunction {
        guard let enumObj = enumObj else {
          XCTFail("No enum found")
          break
        }

        XCTAssertEqual(obj.ffiName, "useEnum")
        XCTAssertEqual(obj.bindingName, "useEnum")

        XCTAssertEqual(obj.kind, OctoFunction.FunctionType.function)
        XCTAssert(obj.attachedTo == nil)
        XCTAssertEqual(obj.returnType, OctoType(
          kind: .Void,
          optional: false,
          mutable: true
        ))

        XCTAssertEqual(obj.arguments.count, 1)
        XCTAssertEqual(obj.arguments[0].ffiName, nil)
        XCTAssertEqual(obj.arguments[0].bindingName, nil)
        XCTAssertEqual(obj.arguments[0].type, OctoType(
          kind: .Enum(enumObj),
          optional: false,
          mutable: true
        ))
        XCTAssertEqual(obj.arguments[0].namedArgument, false)
      }
    }
  }
}
