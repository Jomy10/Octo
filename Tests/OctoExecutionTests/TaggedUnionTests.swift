import Foundation
import XCTest

final class TaggedUnionTests: XCTestCase {
  override class func setUp() {
    super.setUp()

    try! setup(name: "TaggedUnion")
  }

  func testRubyEnums() throws {
    try execRubyTestCase(
      libname: "TaggedUnion",
      name: "taggedUnion"
    )
  }
}
