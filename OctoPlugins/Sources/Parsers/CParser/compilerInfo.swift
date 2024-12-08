import Foundation

struct CompilerInfo {
  /// The standard search paths for the installed clang compiler
  let searchPaths: [SearchPath]
}

enum SearchPath {
  case header(String)
  case framework(String)
}

extension SearchPath {
  var asArgument: String {
    switch (self) {
      case .header(let path):
        return "-I\(path)"
      case .framework(let path):
        return "-F\(path)"
    }
  }
}

enum CommandOutput {
  case stdout
  case stderr
}

struct ExecExitStatus: Error {
  let code: Int32
}

fileprivate func execCommand(_ cmd: String, outputFrom: CommandOutput = .stdout) throws -> String {
  let task = Process()
  let pipe = Pipe()
  switch (outputFrom) {
    case .stdout: task.standardOutput = pipe
    case .stderr: task.standardError = pipe
  }
  task.arguments = ["-c", cmd]
  task.launchPath = "/bin/sh"
  try task.run() // task.launch()
  task.waitUntilExit()

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  if task.terminationStatus != 0 {
    throw ExecExitStatus(code: task.terminationStatus)
  }

  return String(data: data, encoding: .utf8)!
}

fileprivate func execClang(code: String, arguments: String = "", outputFrom: CommandOutput = .stdout) throws -> String {
  // TODO: optionally pass clang path to Octo
  try execCommand("echo '\(code.replacingOccurrences(of: "'", with: "\'"))' | clang \(arguments)", outputFrom: outputFrom)
}

/// Compile a little sample to determine compiler info
func clangInfo(language: String = "c") throws -> CompilerInfo {
  // -fsyntax-only -> create no output
  let clangSampleOutput = try execClang(code: "", arguments: "-x \(language) - -v -fsyntax-only", outputFrom: .stderr)

  let lines = clangSampleOutput.split(separator: "\n")
  let startSearchPaths = lines.firstIndex(of: "#include <...> search starts here:")!
  let endSearchPaths = lines.firstIndex(of: "End of search list.")!
  let searchPaths = lines[(startSearchPaths+1)..<endSearchPaths]

  return CompilerInfo(
    searchPaths: searchPaths.map { line in
      if line.contains("(framework directory)") {
        return SearchPath.framework(
          line
            .replacingOccurrences(of: "(framework directory)", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        )
      } else {
        return SearchPath.header(line.trimmingCharacters(in: .whitespacesAndNewlines))
      }
    }
  )
}
