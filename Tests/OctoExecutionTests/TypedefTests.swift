import Foundation
import XCTest

final class TypedefTests: XCTestCase {
  override class func setUp() {
    super.setUp()

    try! setup(name: "typedef")
  }

  func testRubyEnums() throws {
    try execRubyTestCase(
      libname: "Typedef",
      name: "typedef"
    )
  }
}
