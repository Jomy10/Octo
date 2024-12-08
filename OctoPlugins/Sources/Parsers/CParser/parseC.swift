import Foundation
import OctoIntermediate
import Logging
import OctoMemory
import OctoParseTypes
import Clang
import OctoIO

let clogger = Logger(label: "be.jonaseveraert.Octo.CParser")

@_cdecl("expectsFile")
public func expectsFile() -> UInt8 {
  return 1
}

@_cdecl("parse")
public func plugin_parseC(_ input: UnsafeRawPointer, _ config: UnsafeRawPointer, _ out: UnsafeMutablePointer<UnsafeMutableRawPointer?>) -> UnsafeMutableRawPointer? {
  let inputURL = input.assumingMemoryBound(to: URL.self)
  let cConfig: Rc<CConfig> = Unmanaged<Rc<CConfig>>.fromOpaque(config).takeRetainedValue()
  do {
    let lib = try parseC(input: inputURL.pointee, config: cConfig.takeInner())
    let libPtr = Unmanaged.passRetained(lib).toOpaque()
    out.pointee = libPtr
  } catch let error as ParseError {
    let rcerr = Rc(error)
    return Unmanaged.passRetained(rcerr).toOpaque()
  } catch let error {
    // TODO: should this be handled?
    fatalError(error.localizedDescription)
  }
  //let lib = OctoLibrary()
  //let autoreleaseLib = AutoRemoveReference(lib)
  //let unmanagedLib = Unmanaged.passRetained(autoreleaseLib)
  //out.pointee = unmanagedLib.toOpaque()
  return nil
}

func parseC(input inputURL: URL, config: CConfig) throws -> AutoRemoveReference<OctoLibrary> {
  let compilerInfo = try clangInfo()
  let commandLineArguments = compilerInfo.searchPaths.map { $0.asArgument } + config.clangFlags

  let index = CXIndex(excludeDeclarationsFromPCH: false, displayDiagnostics: false)!
  let unit = try CXTranslationUnit(
    index: index,
    sourceFilename: inputURL.path,
    commandLineArguments: commandLineArguments,
    unsavedFiles: [],
    options: 0
  )

  var highestSeverity: CXDiagnosticSeverity = CXDiagnostic_Ignored
  for diagnostic in unit.diagnostics {
    let severity = diagnostic.severity
    if severity.rawValue > highestSeverity.rawValue {
      highestSeverity = severity
    }
    if severity.rawValue >= config.logLevel.cxDiagnosticSeverity.rawValue {
      print(diagnostic.format(CXDiagnostic_DisplaySourceLocation.rawValue | CXDiagnostic_DisplayColumn.rawValue), to: .stderr)
    }
  }

  if highestSeverity.rawValue >= config.errorLevel.cxDiagnosticSeverity.rawValue {
    throw ParseError("Error while parsing header file with clang")
  }

  let cursor = CXCursor(forTranslationUnit: unit)

  var library = OctoLibrary()
  library.destroy = {
    index.dispose()
    unit.dispose()
  }

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
