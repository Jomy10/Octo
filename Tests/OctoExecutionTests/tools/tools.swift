import Foundation

fileprivate func checkCommand(name: String) throws -> URL? {
  if let path = ProcessInfo.processInfo.environment["\(name.uppercased())_CMD_PATH"] {
    return URL(filePath: path)
  }

  let task = Process()
  let pipe = Pipe()
  task.executableURL = URL(filePath: "/bin/sh")
  task.arguments = ["-c", "command -v \(name)"]
  task.standardOutput = pipe
  try task.run()
  task.waitUntilExit()

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  if task.terminationStatus != 0 {
    return nil
  }

  let path = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .newlines)
  if path == "" {
    return nil
  }

  return URL(filePath: path)
}

struct Tools {
  static let clang: URL? = try? checkCommand(name: "clang")
  static let ruby: URL? = try? checkCommand(name: "ruby")
  static let gem: URL? = try? checkCommand(name: "gem")
}

enum ExecutionError: Error {
  case process(
    command: String,
    terminationStatus: Int32,
    stdout: String,
    stderr: String
  )
}

extension ExecutionError: CustomStringConvertible {
  var description: String {
    switch (self) {
      case .process(command: let command, terminationStatus: let exitCode, stdout: let stdout, stderr: let stderr):
        return """
        While executing \(command)
        Exit code = \(exitCode)
        ===Stdout===
        \(stderr)
        ===Stderr===
        \(stdout)
        """
    }
  }
}

@discardableResult
func execute(
  _ program: URL,
  _ arguments: [String],
  extraLibPath libPath: String? = nil
) throws -> (stdout: String, stderr: String) {
  let (dataOut, dataErr) = try executeData(program, arguments, extraLibPath: libPath)
  return (
    stdout: String(data: dataOut, encoding: .utf8)!.trimmingCharacters(in: .newlines),
    stderr: String(data: dataErr, encoding: .utf8)!.trimmingCharacters(in: .newlines)
  )
}

@discardableResult
func executeData(
  _ program: URL,
  _ arguments: [String],
  extraLibPath libPath: String? = nil
) throws -> (stdout: Data, stderr: Data) {
  let task = Process()
  let pipeOut = Pipe()
  let pipeErr = Pipe()
  task.executableURL = program
  task.arguments = arguments
  task.standardOutput = pipeOut
  task.standardError = pipeErr
  if let libPath = libPath {
    let penv = ProcessInfo.processInfo.environment
    var env = task.environment ?? [:]
    env["LD_LIBRARY_PATH"] = (env["LD_LIBRARY_PATH"] ?? (penv["LD_LIBRARY_PATH"] ?? "")) + ":\(libPath)"
    for (k, v) in penv {
      if k.contains("RUBY") || k.contains("GEM") {
        env[k] = env[k] ?? v
      }
    }
    task.environment = env
  }
  try task.run()
  task.waitUntilExit()

  let dataOut = pipeOut.fileHandleForReading.readDataToEndOfFile()
  let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
  let out = (
    stdout: dataOut,
    stderr: dataErr
  )
  if task.terminationStatus != 0 {
    throw ExecutionError.process(
      command: "\(program.path) \(arguments.map { arg in "\"\(arg)\"" }.joined(separator: " "))",
      terminationStatus: task.terminationStatus,
      stdout: String(data: dataOut, encoding: .utf8)!.trimmingCharacters(in: .newlines),
      stderr: String(data: dataErr, encoding: .utf8)!.trimmingCharacters(in: .newlines)
    )
  }

  return out
}

func testFile(_ name: String) -> URL {
  URL(filePath: "./Tests/OctoExecutionTests/resources/\(name)")
}

func outFile(_ name: String) -> URL {
  URL(filePath: "./.build/tests/\(name)")
}
