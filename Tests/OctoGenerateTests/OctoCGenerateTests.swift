import XCTest
@testable import OctoGenerate
@testable import OctoIntermediate
import Foundation
import ColorizeSwift
import OctoGenerateShared
import OctoParse

final class OctoCGenerateTests: XCTestCase {
  override class func setUp() {
    super.setUp()
    try! FileManager.default.createDirectory(
      atPath: "./.build/tests/",
      withIntermediateDirectories: true,
      attributes: nil
    )
  }

  func testCGenerator() throws {
    let generationOptions = GenerationOptions(
      moduleName: "MyLib",
      indent: "  ",
      libs: ["myLib"],
      languageSpecificOptions: try! OctoGenerator.languageOptions(language: .c, [["useNamespaceInCxx"]] as [[String]])
    )

    var lib = OctoLibrary()
    let fields = [
      OctoField(
        origin: .none,
        name: "A",
        type: OctoType(
          kind: .I32,
          optional: false,
          mutable: false
        )
      ),
      OctoField(
        origin: .none,
        name: "B",
        type: OctoType(
          kind: .CString,
          optional: false,
          mutable: false
        )
      )
    ]
    for field in fields {
      try lib.addObject(field, ref: UUID())
    }
    try lib.addObject(
      OctoRecord(
        origin: .none,
        name: "MyCoolUnion",
        type: .union,
        fields: fields
      ), ref: UUID()
    )

    let code = try OctoGenerator.generate(language: .c, lib: &lib, options: generationOptions)
    let outPath = URL(filePath: "./.build/tests/generateCAndParseAgain.h")
    try code.write(to: outPath)

    let cConfig = try OctoParser.languageOptions(language: .c, [["include", outPath.path]] as [[String]])
    let parseConfig = ParseConfiguration(
      languageSpecificConfig: cConfig!,
      renameOperations: []
    )
    let newLib = try OctoParser.parse(language: .c, config: parseConfig, input: outPath)
    try newLib.inner.finalize()
    lib.memberTest(newLib.inner)
  }
}

protocol MemberEqualityTest {
  func memberTest(_ other: Self)
}

extension OctoLibrary: MemberEqualityTest {
  func memberTest(_ other: Self) {
    XCTAssertEqual(self.ffiLanguage, other.ffiLanguage)
    XCTAssertEqual(self.objects.count, other.objects.count)

    for object in self.objects {
      object.memberTest(other.objects.first(where: { $0.ffiName == object.ffiName })!)
    }
  }
}

extension OctoObject: MemberEqualityTest {
  func memberTest(_ other: OctoObject) {
    XCTAssertEqual(self.ffiName!, other.ffiName!)
    XCTAssertEqual(self.bindingName!, other.bindingName!)
    if let record = self as? OctoRecord {
      let other = other as! OctoRecord
      XCTAssertEqual(record.type, other.type)
      XCTAssertEqual(record.fields.count, other.fields.count)
      for (field, otherField) in zip(record.fields, other.fields) {
        field.memberTest(otherField)
      }
      XCTAssertEqual(record.taggedUnionTagIndex, other.taggedUnionTagIndex)
      XCTAssertEqual(record.taggedUnionValueIndex, other.taggedUnionValueIndex)
      XCTAssertEqual(record.initializers.count, other.initializers.count)
      for (ini, otherIni) in zip(record.initializers, other.initializers) {
        ini.memberTest(otherIni)
      }
      if let deini = record.deinitializer {
        deini.memberTest(other.deinitializer!)
      }
      XCTAssertEqual(record.methods.count, other.methods.count)
      for (method, otherMethod) in zip(record.methods, other.methods) {
        method.memberTest(otherMethod)
      }
      XCTAssertEqual(record.staticMethods.count, other.staticMethods.count)
      for (staticMethod, otherStaticMethod) in zip(record.staticMethods, other.staticMethods) {
        staticMethod.memberTest(otherStaticMethod)
      }
    } else if let field = self as? OctoField {
      let other = other as! OctoField
      field.type.memberTest(other.type)
      XCTAssertEqual(field.taggedUnionCaseName, other.taggedUnionCaseName)
    } else if let e = self as? OctoEnum {
      let other = other as! OctoEnum
      e.type.memberTest(other.type)
      XCTAssertEqual(e.cases.count, other.cases.count)
      for (c, otherC) in zip(e.cases, other.cases) {
        c.memberTest(otherC)
      }
      XCTAssertEqual(e.enumPrefix, other.enumPrefix)
      XCTAssertEqual(e.initializers.count, other.initializers.count)
      for (ini, otherIni) in zip(e.initializers, other.initializers) {
        ini.memberTest(otherIni)
      }
      if let deini = e.deinitializer {
        deini.memberTest(other.deinitializer!)
      }
      XCTAssertEqual(e.methods.count, other.methods.count)
      for (method, otherMethod) in zip(e.methods, other.methods) {
        method.memberTest(otherMethod)
      }
      XCTAssertEqual(e.staticMethods.count, other.staticMethods.count)
      for (staticMethod, otherStaticMethod) in zip(e.staticMethods, other.staticMethods) {
        staticMethod.memberTest(otherStaticMethod)
      }
    } else if let c = self as? OctoEnumCase {
      let other = other as! OctoEnumCase
      XCTAssertEqual(c.value, other.value)
      XCTAssertEqual(c.strippedName, other.strippedName)
    } else if let fn = self as? OctoFunction {
      let other = other as! OctoFunction
      XCTAssertEqual(fn.arguments.count, other.arguments.count)
      for (arg, otherArg) in zip(fn.arguments, other.arguments) {
        arg.memberTest(otherArg)
      }
      fn.returnType.memberTest(other.returnType)
      XCTAssertEqual(fn.kind, other.kind)
      if let attachedTo = fn.attachedTo {
        (attachedTo as OctoObject).memberTest(other.attachedTo! as OctoObject)
      }
      XCTAssertEqual(fn.selfArgumentIndex, other.selfArgumentIndex)
      XCTAssertEqual(fn.initializerType, other.initializerType)
    } else if let arg = self as? OctoArgument {
      let other = other as! OctoArgument
      arg.type.memberTest(other.type)
      XCTAssertEqual(arg.namedArgument, other.namedArgument)
      XCTAssertEqual(arg.isSelfArgument, other.isSelfArgument)
    } else {
      fatalError("bug")
    }
  }
}

extension OctoType: MemberEqualityTest {
  func memberTest(_ other: OctoType) {
    XCTAssertEqual(self.optional, other.optional)
    XCTAssertEqual(self.mutable, other.mutable)

    switch (self.kind) {
      case .Record(let record):
        if case .Record(let otherRecord) = other.kind {
          record.memberTest(otherRecord)
        } else {
          XCTFail("Types are not equal: \(self) and \(other)")
        }
      case .Enum(let e):
        if case .Enum(let otherE) = other.kind {
          e.memberTest(otherE)
        } else {
          XCTFail("Types are not equal: \(self) and \(other)")
        }
      default:
        XCTAssertEqual(self.kind, other.kind)
    }
  }
}
