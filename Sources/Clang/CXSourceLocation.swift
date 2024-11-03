import clang_c

extension CXSourceLocation {
  public var expansionLocation: (
    file: CXFile,
    line: UInt32,
    column: UInt32,
    offset: UInt32
  ) {
    var file: CXFile? = nil
    var line: UInt32 = 0
    var column: UInt32 = 0
    var offset: UInt32 = 0
    clang_getExpansionLocation(self, &file, &line, &column, &offset)
    return (file: file!, line: line, column: column, offset: offset)
  }
  // TODO: clang_getFileLocation() = where the macro was expanded
}

extension CXSourceLocation: CustomStringConvertible {
  public var description: String {
    let (file, line, column, offset) = self.expansionLocation
    return "\(file)@\(line):\(column)"
  }
}
