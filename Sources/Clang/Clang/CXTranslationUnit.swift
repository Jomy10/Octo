import clang_c

fileprivate extension Collection {
  func unsafeAllocateCopy() -> UnsafeBufferPointer<Self.Element> {
    let copy = UnsafeMutableBufferPointer<Self.Element>.allocate(capacity: self.underestimatedCount)
    _ = copy.initialize(from: self)
    return UnsafeBufferPointer(start: copy.baseAddress!, count: self.underestimatedCount)
  }
}

fileprivate extension String {
  func unsafeAllocateUTF8Copy() -> UnsafeBufferPointer<CChar> {
    self.utf8CString.unsafeAllocateCopy()
  }
}

extension CXTranslationUnit {
  //public init?(
  //  index: CXIndex,
  //  sourceFilename: String?,
  //  commandLineArguments: [String] = [],
  //  unsavedFiles: [CXUnsavedFile] = [],
  //  options: UInt32 = 0
  //) {
  //  var uf = unsavedFiles
  //  let args: UnsafePointer<UnsafePointer<CChar>?>? = commandLineArguments.map { $0.unsafeAllocateUTF8Copy().baseAddress }.unsafeAllocateCopy().baseAddress
  //  //let constArgs: UnsafePointer<UnsafePointer<CChar>?>? = UnsafePointer(args.baseAddress)
  //  guard let unit = clang_parseTranslationUnit(
  //    index,
  //    sourceFilename,
  //    args,
  //    Int32(commandLineArguments.count),
  //    uf.withUnsafeMutableBufferPointer() { $0.baseAddress },
  //    UInt32(unsavedFiles.count),
  //    options
  //  ) else {
  //    return nil
  //  }
  //  self = unit
  //  UnsafeBufferPointer(start: args, count: commandLineArguments.count).forEach { $0!.deallocate() }
  //  args!.deallocate()
  //}

  struct Error: Swift.Error, CustomStringConvertible {
    let code: CXErrorCode

    var description: String {
      "\(self.code): \(self.reason)"
    }

    var reason: String {
      switch (code) {
        case CXError_Success:
          return "Success"
        case CXError_Failure:
          return "failure"
        case CXError_Crashed:
          return "crashed"
        case CXError_InvalidArguments:
          return "InvalidArguments"
        case CXError_ASTReadError:
          return "ASTReadError: AST deserialization failed"
        default:
          fatalError("unreachable")
      }
    }
  }

  public init(
    index: CXIndex,
    sourceFilename: String?,
    commandLineArguments: [String] = [],
    unsavedFiles: [CXUnsavedFile] = [],
    options: UInt32 = 0
  ) throws  {
    var uf = unsavedFiles
    let args: UnsafePointer<UnsafePointer<CChar>?>? = commandLineArguments.map { $0.unsafeAllocateUTF8Copy().baseAddress }.unsafeAllocateCopy().baseAddress

    var unit: CXTranslationUnit? = nil
    let errCode = clang_parseTranslationUnit2(
      index,
      sourceFilename,
      args, Int32(commandLineArguments.count),
      uf.withUnsafeMutableBufferPointer() { $0.baseAddress }, UInt32(unsavedFiles.count),
      options,
      &unit
    )

    if errCode != CXError_Success {
      throw Self.Error(code: errCode)
    }

    self = unit!

    UnsafeBufferPointer(start: args, count: commandLineArguments.count).forEach { $0!.deallocate() }
    args!.deallocate()
  }

  public var numDiagnostics: UInt32 {
    clang_getNumDiagnostics(self)
  }

  public func getDiagnostic(_ i: UInt32) -> CXDiagnostic {
    clang_getDiagnostic(self, i)
  }

  public var diagnostics: [CXDiagnostic] {
    (0..<self.numDiagnostics).map { self.getDiagnostic($0) }
  }

  public func dispose() {
    clang_disposeTranslationUnit(self)
  }
}
