import XCTest
@testable import OctoGenerate
import OctoIntermediate
import Foundation
import ColorizeSwift

func formatCode(_ code: String) -> String {
  code.unicodeScalars.map {
    if $0 == " " {
      return String($0).onRed()
    } else {
      return String($0)
    }
  }.joined(separator: "")
}

func findDifferences(_ got: String, _ expected: String) -> String {
  zip(got, expected).map {
    if $0 == $1 {
      return String($0)
    } else {
      return String($0).onRed()
    }
  }.joined(separator: "")
}

func testEq(_ file: String, _ expected: String, limit: Int? = nil) throws {
  var got = try String(contentsOfFile: file)
  if let limit = limit {
    got = String(got[..<got.index(got.startIndex, offsetBy: limit)])
  }
  if (got == expected) {
    return
  } else {
    XCTFail("""
    Assertion failed: sources are not equal
    \(formatCode(got))
    -----------------
    \(formatCode(expected))
    =================
    \(findDifferences(got, expected))
    """)
  }
}

final class OctoGenerateTests: XCTestCase {
  override class func setUp() {
    super.setUp()
    try! FileManager.default.createDirectory(
      atPath: "./.build/tests/",
      withIntermediateDirectories: true,
      attributes: nil
    )
  }

  let generationOptions = GenerationOptions(
    moduleName: "MyLib",
    indent: "  ",
    libs: ["mylib"]
  )

  func testParseRecord() throws {
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

    let code = try OctoGenerator.generate(language: .ruby, lib: lib, options: generationOptions)
    let outPath = "./.build/tests/parseRecordTest.rb"
    try code.write(to: URL(filePath: outPath))

    let expected = """
    require 'ffi'

    module MyLib_FFI
      extend FFI::Library
      ffi_lib 'mylib'
    \("  ")
      class MyCoolUnion < FFI::Union
        layout :A, :int32,
               :B, :string
      end
    end
    """
    try testEq(outPath, expected, limit: expected.count)
  }
}
