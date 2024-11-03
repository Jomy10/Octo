struct ConversionOptions {
  let libraryName: String
  let ffiLibraryName: String?
  let indent: String

  enum IndentType {
    case spaces
    case tabs

    var str: String {
      switch (self) {
        case .spaces: return " "
        case .tabs: return "\t"
      }
    }
  }

  static func rubyOptions(
    libraryName: String,
    ffiLibraryName: String? = nil,
    indent: (IndentType, Int) = (.spaces, 2)
  ) -> Self {
    ConversionOptions(
      libraryName: libraryName,
      ffiLibraryName: ffiLibraryName ?? libraryName,
      indent: String(repeating: indent.0.str, count: indent.1)
    )
  }
}
