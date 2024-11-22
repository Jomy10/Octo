import XCTest
@testable import OctoIntermediate

final class OctoIntermediateTests: XCTestCase {
  func testRecord() throws {
    var library = OctoLibrary()
    let field = OctoField(
      origin: .none,
      name: "a",
      type: OctoType(
        kind: .I8,
        optional: false,
        mutable: false
      )
    )
    let record = OctoRecord(
      origin: .none,
      name: "MyStruct",
      type: .struct
    )
    record.addField(field)

    try library.addObject(field, ref: 0)
    try library.addObject(record, ref: 1)

    XCTAssertEqual(library.objects, [field, record])
    guard let libRecord = library.getObject(forRef: 1) as? OctoRecord else {
      XCTFail("object is not a record or doesn't exist")
      return
    }
    XCTAssertEqual(libRecord, record)
    XCTAssertEqual(libRecord.fields, [field])
  }

  func testAttach() throws {
    var library = OctoLibrary()
    let function = OctoFunction(
      origin: .none,
      name: "myCoolFunction",
      returnType: OctoType(
        kind: .Void,
        optional: false,
        mutable: false
      )
    )
    try library.addObject(function, ref: 0)
    let myEnum = OctoEnum(
      origin: .none,
      name: "MyEmptyEnum",
      type: OctoType(
        kind: .I8,
        optional: false,
        mutable: false
      )
    )
    try library.addObject(myEnum, ref: 1)

    try function.attach(to: myEnum, kind: .initializer)

    guard let libEnum = library.getObject(forRef: 1) as? OctoEnum else {
      XCTFail("object is not an enum or doesn't exist")
      return
    }

    XCTAssertEqual(libEnum.initializers, [function])
  }
}
