#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unhandled platform in OctoIO (TODO)")
#endif

#if canImport(Darwin) || canImport(Glibc)

public enum IOStream: TextOutputStream {
  case stdout
  case stderr

  #if canImport(Darwin)
  var to: UnsafeMutablePointer<FILE> {
    switch (self) {
      case .stdout: return Darwin.stdout
      case .stderr: return Darwin.stderr
    }
  }
  #elseif canImport(Glibc)
  var to: UnsafeMutablePonter<FILE> {
    switch (self) {
      case .stdout: return Glibc.stdout
      case .stderr: return Glibc.stderr
    }
  }
  #endif

  public mutating func write(_ string: String) {
    fputs(string, self.to)
  }
}

#endif

public func print(_ msgs: String..., to stream: IOStream) {
  var s = stream
  print(msgs.joined(separator: " "), to: &s)
}

// TODO: other platforms
