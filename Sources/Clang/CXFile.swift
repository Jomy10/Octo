import clang_c

extension CXFile {
  public var fileName: String {
    clang_getFileName(self).toString()!
  }
}

extension CXFile: CustomStringConvertible {
  public var description: String {
    self.fileName
  }
}

extension CXFile: Equatable {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    clang_File_isEqual(lhs, rhs) != 0
  }
}
