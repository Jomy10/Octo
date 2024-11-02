import Foundation

struct CompilerInfo {
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

/// Compile a little sample to determine compiler info
func clangInfo(language: String = "c") -> CompilerInfo {
  // -fsyntax-only -> create no output
  let clangSampleCommand = "echo '' | clang -x \(language) - -v -fsyntax-only"
  let task = Process()
  let pipe = Pipe()
  task.standardError = pipe
  task.arguments = ["-c", clangSampleCommand]
  task.launchPath = "/bin/sh"
  task.launch()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  let clangSampleOutput = String(data: data, encoding: .utf8)!

  let lines = clangSampleOutput.split(separator: "\n")
  let startSearchPaths = lines.firstIndex(of: "#include <...> search starts here:")!
  let endSearchPaths = lines.firstIndex(of: "End of search list.")!
  let searchPaths = lines[(startSearchPaths+1)..<endSearchPaths]

  print(startSearchPaths, endSearchPaths, searchPaths)

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
