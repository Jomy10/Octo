import Foundation
import XCTest

/// Tests:
/// - Records
/// - methods
/// - initializer
/// - instance methods
final class AdderTests: XCTestCase {
  override class func setUp() {
    super.setUp()

    try! setup(name: "adder")

    // General tools info
    if let ruby = Tools.ruby {
      let (rubyVersion, _) = try! execute(ruby, ["--version"])
      print("Ruby version: \(rubyVersion)")
    }

    if let gem = Tools.gem {
      let (gemVersion, _) = try! execute(gem, ["--version"])
      print("Gem version: \(gemVersion)")
      let (gems, _) = try! execute(gem, ["list"])
      print(gems.split(whereSeparator: \.isNewline).filter { gem in
        gem.contains("ffi") || gem.contains("json")
      })
    }
  }

  func testRubyAdder() throws {
    try execRubyTestCase(libname: "Adder", name: "adder")
  }
}
