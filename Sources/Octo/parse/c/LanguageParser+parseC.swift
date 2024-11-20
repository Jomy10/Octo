import Foundation
import Clang
import OctoIO

extension LanguageParser {
  static func parseC(config: ParseConfiguration) throws -> OctoLibrary {
    let compilerInfo = try clangInfo()
    let commandLineArguments = compilerInfo.searchPaths.map { $0.asArgument } + config.cConfig!.clangFlags.map { String($0) }
    let index = CXIndex(excludeDeclarationsFromPCH: false, displayDiagnostics: false)!
    /// Parse the header file
    let unit = try CXTranslationUnit(
      index: index,
      sourceFilename: config.cConfig!.headerFile.path,
      commandLineArguments: commandLineArguments,
      unsavedFiles: [],
      options: 0
    )

    let destroy = {
      index.dispose()
      unit.dispose()
    }

    var highestSeverity: CXDiagnosticSeverity = CXDiagnostic_Ignored
    for diagnostic in unit.diagnostics {
      let severity = diagnostic.severity
      if severity.rawValue > highestSeverity.rawValue {
        highestSeverity = severity
      }
      if severity.rawValue >= config.cConfig!.logLevel.cxDiagnosticSeverity.rawValue {
        print(diagnostic.format(CXDiagnostic_DisplaySourceLocation.rawValue | CXDiagnostic_DisplayColumn.rawValue), to: .stderr)
      }
    }

    if highestSeverity.rawValue >= config.cConfig!.errorLevel.cxDiagnosticSeverity.rawValue {
      octoLogger.fatal("Error while parsing header file with clang") // TODO: throw
    }

    let cursor = CXCursor(forTranslationUnit: unit)

    var library: OctoLibrary = OctoLibrary(name: config.outputLibraryName, destroy: destroy)

    try cursor.visitChildren(visitC, userData: &library)

    return library
  }
}
