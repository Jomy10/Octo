import Foundation
import XCTest

/// Testing of an initializer with a self parameter: `void init(Self* out);`
final class InitSelfParamTests: XCTestCase {
  override class func setUp() {
    super.setUp()

    try! setup(name: "initSelfParam")
  }

  func testRubyInitSelfParam() throws {
    try execRubyTestCase(
      libname: "InitSelfParam",
      name: "initSelfParam"
    )
  }
}
