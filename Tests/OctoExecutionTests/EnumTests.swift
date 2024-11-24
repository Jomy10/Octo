import Foundation
import XCTest

final class EnumTests: XCTestCase {
  override class func setUp() {
    super.setUp()

    try! setup(name: "enums")
  }

  func testRubyEnums() throws {
    try execRubyTestCase(
      libname: "EnumTest",
      name: "enums"
    )
  }
}
