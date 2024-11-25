import SystemPackage

#if canImport(Darwin)
import Darwin
#elseif os(Windows)
import ucrt
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#elseif canImport(Android)
import Android
#else
#error("Unsupported Platform")
#endif

func system_chmod(
  _ pathname: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode
) -> CInt {
  #if os(Windows)
  return _chmod(pathname, mode)
  #else
  return chmod(pathname, mode)
  #endif
}

extension FilePath {
  func chmod(_ mode: FilePermissions) throws {
    #if !os(Windows)
    try self.withCString {
      try Self.chmod($0, mode)
    }
    #else
    try self.withPlatformString {
      try Self.chmod($0, mode)
    }
    #endif
  }

  static func chmod(
    _ pathname: UnsafePointer<CInterop.PlatformChar>,
    _ mode: FilePermissions
  ) throws {
    try Self._chmod(pathname, mode).get()
  }

  static func _chmod(
    _ pathname: UnsafePointer<CInterop.PlatformChar>,
    _ mode: FilePermissions
  ) -> Result<(), Errno> {
    let res = system_chmod(pathname, mode.rawValue)
    if res == 0 {
      return .success(())
    } else {
      return .failure(Errno(rawValue: res))
    }
  }
}
