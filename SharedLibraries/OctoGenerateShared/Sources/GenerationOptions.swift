public struct GenerationOptions {
  public let moduleName: String
  public let indent: String
  /// Libraries to link against
  public let libs: [String]
  public let languageSpecificOptions: UnsafeMutableRawPointer?

  public init(
    moduleName: String,
    indent: String,
    libs: [String],
    languageSpecificOptions: UnsafeMutableRawPointer?
  ) {
    self.moduleName = moduleName
    self.indent = indent
    self.libs = libs
    self.languageSpecificOptions = languageSpecificOptions
  }
}
