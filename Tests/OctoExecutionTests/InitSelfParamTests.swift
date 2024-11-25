import Foundation
import XCTest

final class InitSelfParamTests: XCTestCase {
  override class func setUp() {
    super.setUp()

    try! setup(name: "initSelfParam")
  }

  func testRubyEnums() throws {
    try execRubyTestCase(
      libname: "InitSelfParam",
      name: "initSelfParam"
    )
  }
}
