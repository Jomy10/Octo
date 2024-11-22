import Foundation
import Clang
import OctoIO
import OctoIntermediate

extension OctoParser {
  static func parseC(input inputURL: URL, config: ParseConfiguration) throws -> AutoRemoveReference<OctoLibrary> {
    if !inputURL.isFileURL {
      throw InputError.isDir(url: inputURL)
    }

    let compilerInfo = try clangInfo()
    let cConfig = config.cConfig!
    let commandLineArguments = compilerInfo.searchPaths.map { $0.asArgument } + cConfig.clangFlags

    let index = CXIndex(excludeDeclarationsFromPCH: false, displayDiagnostics: false)!
    let unit = try CXTranslationUnit(
      index: index,
      sourceFilename: inputURL.path,
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
      if severity.rawValue >= cConfig.logLevel.cxDiagnosticSeverity.rawValue {
        // TODO: log instead? -> Clang logLevel replaced by verbosity level?
        print(diagnostic.format(CXDiagnostic_DisplaySourceLocation.rawValue | CXDiagnostic_DisplayColumn.rawValue), to: .stderr)
      }
    }

    if highestSeverity.rawValue >= cConfig.errorLevel.cxDiagnosticSeverity.rawValue {
      throw ParseError("Error while parsing header file with clang")
    }

    let cursor = CXCursor(forTranslationUnit: unit)

    var library: OctoLibrary = OctoLibrary()
    library.destroy = destroy

    do {
      try cursor.visitChildren(visitC, userData: &library)
    } catch is CXCursor.VisitChildrenBreak {
      guard let err = C_PARSING_ERROR else {
        fatalError("unreachable (bug)")
      }

      throw err
    } catch {
      fatalError("unreachable")
    }

    return AutoRemoveReference(library)
  }
}
