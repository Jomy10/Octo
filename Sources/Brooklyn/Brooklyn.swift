import Foundation
import Clang
import ArgumentParser

extension URL {
  var isDirectory: Bool {
    (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
  }
}

internal func unhandledKind(_ kind: some CXKind, location: CXSourceLocation? = nil, file: String = #file, function: String = #function, line: Int = #line) -> Never {
  var msg = "Unhandled \(kind.kindName) (\(kind.rawValue)): \(kind.spelling!) @ \(file) \(function):\(line)"
  if let location = location {
    msg += "\nOriginated at \(location)"
  }
  fatalError(msg)
}

internal func unhandledToken(_ token: CXToken, translationUnit: CXTranslationUnit, file: String = #file, function: String = #function, line: Int = #line) -> Never {
  fatalError("Unhandled token: \(token.spelling(translationUnit: translationUnit)!) @ \(file) \(function):\(line)\nOriginated at \(token.sourceLocation(translationUnit: translationUnit))")
}

@main
struct Brooklyn: ParsableCommand {
  @Option(name: .shortAndLong, help: "At which severity level of diagnostics does the program exit")
  var severityError: String = "error"

  @Option(name: .shortAndLong)
  var logLevel: String = "warning"

  @Option(name: .shortAndLong, help: "Pass arguments to clang")
  var clangFlag: [String] = []

  @Option(name: [.long, .customShort("h")], help: "Headers to include in output. #included headers not specified in this variable will not be included")
  var includeHeaders: [String] = []

  @Argument(help: "The header to compile")
  var headerFile: String

  func isHeaderIncluded(_ headerFile: String) throws -> Bool {
    if self.includeHeaders.count == 0 {
      return true
    }

    for includeHeader in self.includeHeaders.filter({ $0.contains("*") }) {
      let _ = includeHeader
      fatalError("unimplemented")
      //let pattern = try Glob.Pattern(includeHeader)
      //if pattern.match(headerFile) {
      //  return true
      //}
    }

    let headerURL = URL(fileURLWithPath: headerFile)
    for includeHeader in self.includeHeaders.filter({ !$0.contains("*") }) {
      let url = URL(fileURLWithPath: includeHeader, relativeTo: URL.currentDirectory())
      if url.isDirectory {
        if headerURL.absoluteString.hasPrefix(url.absoluteString) { return true }
      } else {
        if url == headerURL { return true }
      }
    }

    return false
  }

  var includeHeadersValues: [URL] {
    includeHeaders
      .map{ h in
        URL(fileURLWithPath: h, relativeTo: URL.currentDirectory())
      }
  }

  var severityValue: CXDiagnosticSeverity {
    guard let severity = CXDiagnosticSeverity(fromString: self.severityError) else {
      fatalError("Unknown severity error \(self.severityError). Valid values are `ignored`, `note`, `warning`, `error` or `fatal`")
    }
    return severity
  }

  var logLevelValue: CXDiagnosticSeverity {
    guard let logLevel = CXDiagnosticSeverity(fromString: self.logLevel) else {
      fatalError("Unknown log level \(self.logLevel). Valid values are `ignored`, `note`, `warning`, `error` or `fatal`")
    }
    return logLevel
  }

  mutating func run() throws {
    let compilerInfo = try clangInfo()
    let commandLineArguments = compilerInfo.searchPaths.map { $0.asArgument } + self.clangFlag
    print(commandLineArguments)
    let index = CXIndex(excludeDeclarationsFromPCH: false, displayDiagnostics: false)!
    defer { index.dispose() }
    guard let unit = CXTranslationUnit(
      index: index,
      sourceFilename: self.headerFile,
      commandLineArguments: commandLineArguments,
      unsavedFiles: [],
      options: 0
    ) else {
      fatalError("Unable to parse translation unit. Quitting\n")
    }
    defer { unit.dispose() }

    var highestSeverity: CXDiagnosticSeverity = CXDiagnostic_Ignored
    for diagnostic in unit.diagnostics {
      let severity = diagnostic.severity
      if max(severity.rawValue, highestSeverity.rawValue) > highestSeverity.rawValue {
        highestSeverity = severity
      }
      if severity.rawValue >= self.logLevelValue.rawValue {
        print(diagnostic.format(CXDiagnostic_DisplaySourceLocation.rawValue | CXDiagnostic_DisplayColumn.rawValue))
      }
    }

    if highestSeverity.rawValue >= self.severityValue.rawValue {
      fatalError("Error while parsing header file")
    }

    let cursor = CXCursor(forTranslationUnit: unit)

    var prog: CProgram = CProgram()

    do {
      try cursor.visitChildren(visit, userData: &prog)
    } catch let err {
      fatalError("\(err)")
    }

    print(prog)

    let rubyOptions = ConversionOptions.rubyOptions(
      libraryName: "Test",
      ffiLibraryName: "test"
    )
    let rubySource = try! prog.convert(language: .ruby, headerIncludes: isHeaderIncluded, options: rubyOptions)
    print(rubySource)
  }
}
