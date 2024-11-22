import Foundation
import OctoIntermediate
import Clang

extension OctoOrigin {
  static func c(_ loc: CXSourceLocation) -> Self {
    let (file: file, line: line, column: column, offset: _) = loc.expansionLocation
    return .file(file: URL(filePath: file.fileName), line: UInt(line), column: UInt(column))
  }
}
