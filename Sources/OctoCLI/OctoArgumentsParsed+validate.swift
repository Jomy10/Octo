import Foundation

fileprivate extension URL {
  var exists: (exists: Bool, isDir: Bool) {
    let isDirPtr: UnsafeMutablePointer<ObjCBool>? = nil
    let exists = FileManager.default.fileExists(atPath: self.absoluteString, isDirectory: isDirPtr)
    let isDir = isDirPtr?.pointee.boolValue ?? false
    return (exists: exists, isDir: isDir)
  }
}

extension OctoArgumentsParsed {
  struct ValidationError: Swift.Error {
    let msg: String

    init(_ msg: String) {
      self.msg = msg
    }
  }

  func validate() throws {
    guard (self.outputLibraryName.allSatisfy { $0.isLetter || $0 == "_" }) else {
      throw ValidationError("Library name can only contain letters and underscores")
    }

    let inputLocationExists = self.inputLocation.exists
    guard inputLocationExists.exists else {
      throw ValidationError("Input location \"\(self.inputLocation)\" doesn't exist")
    }
    switch (self.inputLanguage) {
      case .c:
        if inputLocationExists.isDir { throw ValidationError("Input location for C should be a file, not a directory") }
      default:
        print("Unhandled input language \(self.inputLanguage) in validation")
    }

    // TODO: unused language options
    // TODO: unknown attributes

    for (language, args) in self.outputOptions {
      let outputLocationExists = args.outputLocation.exists
      switch (language) {
        case .ruby:
          if outputLocationExists.isDir {
            throw ValidationError("Output location for Ruby should be a file, not a directory")
          }
        default:
          break
      }

      // TODO: unused language options
    }
  }
}
