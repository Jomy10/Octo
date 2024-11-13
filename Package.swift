// swift-tools-version: 5.7

import PackageDescription
//import _Concurrency
//import Foundation

//extension URL {
//    var isDirectory: Bool {
//       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
//    }
//}

//extension String {
//  func parseCommandLine() -> [String] {
//    return self.components(separatedBy: CharacterSet(charactersIn: "\n "))
//      .filter { $0 != "" }
//  }
//}

///// Returns the command path if it exists in PATH
//func checkCommand(name: String) -> URL? {
//  let task = Process()
//  let pipe = Pipe()
//  task.executableURL = URL(fileURLWithPath: "/bin/sh")
//  task.arguments = ["-c", "command -v \(name)"]
//  task.standardOutput = pipe
//  try! task.run()
//  task.waitUntilExit()

//  let data = pipe.fileHandleForReading.readDataToEndOfFile()
//  if task.terminationStatus != 0 {
//    return nil
//  }

//  let path = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .newlines)
//  if path == "" {
//    return nil
//  }

//  return URL(fileURLWithPath: path)
//}

//final class TaskData<T>: Sendable {
//  private let _data: T

//  init(_ data: T) {
//    self._data = data
//  }

//  var data: T {
//    self._data
//  }
//}

//final class Signal<T>: Sendable {
//  private var value: T? = nil
//  private let semaphore = DispatchSemaphore(value: 0)

//  init() {}

//  func send(_ value: T) {
//    self.value = value
//    self.semaphore.signal()
//  }

//  func wait() -> T {
//    self.semaphore.wait()
//    return self.value!
//  }
//}

//struct ExecuteError: Error {
//  let code: Int32?
//  let stderr: String
//}

//typealias ExecuteResult = Result<(stdout: Data, stderr: Data), ExecuteError>

//func string(fromData data: Data) -> String {
//  String(data: data, encoding: .utf8)!.trimmingCharacters(in: .newlines)
//}

//func executeNoWait(executableURL: URL, arguments: [String]) -> Signal<ExecuteResult> {
//  let task = Process()
//  let stdoutPipe = Pipe()
//  let stderrPipe = Pipe()
//  task.executableURL = executableURL
//  task.arguments = arguments
//  task.standardOutput = stdoutPipe
//  task.standardError = stderrPipe
//  let signal: Signal<ExecuteResult> = Signal()
//  do {
//    try task.run()
//  } catch let err {
//    signal.send(ExecuteResult.failure(ExecuteError(code: nil, stderr: "\(err) (executing: \(executableURL.path) \(arguments))")))
//    return signal
//  }

//  let taskData: TaskData<Process> = TaskData(task)
//  Task {
//    taskData.data.waitUntilExit()

//    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
//    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

//    if taskData.data.terminationStatus != 0 {
//      signal.send(ExecuteResult.failure(ExecuteError(code: taskData.data.terminationStatus, stderr: string(fromData: stderrData))))
//    } else {
//      signal.send(ExecuteResult.success((stdout: stdoutData, stderr: stderrData)))
//    }
//  }

//  return signal
//}

//func execute(executableURL: URL, arguments: [String]) -> ExecuteResult {
//  let signal = executeNoWait(executableURL: executableURL, arguments: arguments)
//  return signal.wait()
//}

//extension String: Error {}

//func brewLLVMConfigPath(brewURL: URL) -> Result<URL, String> {
//  //guard let brewURL = checkCommand(name: "brew") else { return .error("brew command not found") }

//  let versionsSignal = executeNoWait(executableURL: brewURL, arguments: ["list", "--versions", "llvm"])
//  let cellarPathSignal = executeNoWait(executableURL: brewURL, arguments: ["--cellar", "llvm"])

//  let version: String
//  switch (versionsSignal.wait()) {
//    case .failure(let err):
//      return .failure(err.stderr)
//    case .success((stdout: let stdout, stderr: _)):
//      let versionsString = string(fromData: stdout)
//      let versions = versionsString.split(whereSeparator: { c in c.isNewline }).map { line in
//        line.split(separator: " ")
//      }.filter { s in
//        if s.count != 2 {
//          print("[WARNING] \(s)")
//        }
//        return s.count == 2
//      }.map { (versionSplit: [Substring]) in
//        let versionString: Substring = versionSplit[1]
//        return versionString.split(separator: ".").map { Int(String($0))! }
//      }.filter { (version: [Int]) in
//        if version.count != 3 {
//          print("[WARNING] \(version)")
//        }
//        return version.count == 3
//      }
//      let latestVersion = versions.reduce([0, 0, 0], { (res, el) in
//        if res[0] == el[0] {
//          if res[1] == el[1] {
//            if res[2] == el[2] {
//              return res
//            } else {
//              return res[2] > el[2] ? res : el
//            }
//          } else {
//            return res[1] > el[1] ? res : el
//          }
//        } else {
//          return res[0] > el[0] ? res : el
//        }
//      })
//      if latestVersion == [0, 0, 0] {
//        return .failure("Couldn't determine latest LLVM version")
//      }
//      version = latestVersion.map { "\($0)" }.joined(separator: ".")
//  }

//  let cellarPath: String
//  switch (cellarPathSignal.wait()) {
//    case .failure(let err):
//      return .failure(err.stderr)
//    case .success((stdout: let stdout, stderr: _)):
//      cellarPath = string(fromData: stdout)
//  }

//  let path = URL(fileURLWithPath: "\(cellarPath)/\(version)/bin/llvm-config")
//  if !((try? path.checkResourceIsReachable()) ?? false) {
//    return .failure("\(path) doesn't exist or is not reachable")
//  }
//  return .success(path)
//}

//func llvmFlags() -> [String] {
//  let env = ProcessInfo.processInfo.environment
//  let llvmConfigCmd: URL
//  if let llvmConfigEnv = env["LLVM_CONFIG"] {
//    llvmConfigCmd = URL(fileURLWithPath: llvmConfigEnv)
//  } else if let llvmCmdPath = checkCommand(name: "llvm-config") {
//    llvmConfigCmd = llvmCmdPath
//  } else if let brew = checkCommand(name: "brew") {
//    switch (brewLLVMConfigPath(brewURL: brew)) {
//    case .failure(let errorReason):
//      fatalError("COMPILATION ERROR: Couldn't find llvm through brew\n\(errorReason)")
//    case .success(let url):
//      llvmConfigCmd = url
//    }
//  } else {
//    fatalError("COMPILATION ERROR: llvm not installed")
//  }

//  switch (execute(executableURL: llvmConfigCmd, arguments: ["--cflags", "--ldflags", "--libs", "--system-libs"])) {
//    case .failure(let error):
//      fatalError(error.stderr)
//    case .success((stdout: let stdout, stderr: _)):
//      return string(fromData: stdout).parseCommandLine().map { String($0) }
//  }
//}

//let fm = FileManager.default
//func contentsOfDirFlat(_ path: String) throws -> [String] {
//  let items = try fm.contentsOfDirectory(atPath: path)
//  return try items.flatMap { (item: String) -> [String] in
//    if URL(fileURLWithPath: item).isDirectory {
//      return try contentsOfDirFlat(item)
//    } else {
//      return [item]
//    }
//  }
//}

//func modulemap(llvmFlags: [String]) -> String {
//  let i = llvmFlags
//    .filter { $0.hasPrefix("-I") }
//    .map { $0[$0.index($0.startIndex, offsetBy: 2)...] }
//    .first(where: { URL(fileURLWithPath: "\($0)/clang-c").isDirectory })

//  guard let headerInclude = i else {
//    fatalError("COMPILATION ERROR: 'clang-c' library include directory not found")
//  }

//  let clang_cPath = "\(headerInclude)/clang-c"

//  //let contentsOfDir: (String) throws -> [String] = { (path: String) throws -> [String] in
//  //  let items = try fm.contentsOfDirectory(atPath: path)
//  //  return try items.compactMap { (item: String) -> [String] in
//  //    if URL(fileURLWithPath: item).isDirectory {
//  //      return try contentsOfDir(item)
//  //    } else {
//  //      return [item]
//  //    }
//  //  }
//  //}

//  let items: [String]
//  do {
//    items = try contentsOfDirFlat(clang_cPath)
//  } catch let error {
//    fatalError("COMPILATION ERROR: \(error)")
//  }

//  return """
//  module clang_c {
//    \(items.map { "header \($0)" }.joined(separator: "\n  "))
//    link "clang"
//  }
//  """
//}

//let llvmFlagsArr = llvmFlags()

////let moduleMapURL = URL(fileURLWithPath: "Sources/clang_c/module.modulemap", relativeTo: URL.currentDirectory())
//let moduleMapURL = URL(fileURLWithPath: "Sources/clang_c/module.modulemap")
//print("Writing to \(moduleMapURL)")

//do {
//  try modulemap(llvmFlags: llvmFlagsArr)
//    .write(to: moduleMapURL, atomically: true, encoding: .utf8)
//} catch let error {
//  fatalError("\(error)")
//}

//let settings: ([CSetting], [LinkerSetting]) = llvmFlagsArr.reduce(([], [])) { (res, flag) in
//  let secondIndex: String.Index = flag.index(flag.startIndex, offsetBy: 2)
//  let flagValue: Substring = flag[secondIndex...]
//  switch (flag[flag.startIndex..<secondIndex]) {
//    case "-L": return (res.0, res.1 + [LinkerSetting.unsafeFlags([flag])])
//    case "-l":
//      return (res.0, res.1 + [LinkerSetting.linkedLibrary(String(flagValue))])
//    case "-D": return (res.0 + [CSetting.define(String(flagValue))], res.1)
//    default:
//      return (res.0 + [CSetting.unsafeFlags([flag])], res.1)
//  }
//}

let package = Package(
  name: "Octo",
  platforms: [.macOS(.v13)],
  products: [
    .executable(
      name: "octo",
      targets: ["OctoCLI"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
    .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0")
    //.package(url: "https://github.com/davbeck/swift-glob.git", from: "0.1.0"),
  ],
  targets: [
    .executableTarget(
      name: "OctoCLI",
      dependencies: [
        "Octo",
        "OctoIO",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "TOMLKit", package: "TOMLKit")
      ]
    ),
    .target(
      name: "Octo",
      dependencies: [
        "Clang",
        "OctoIO"
        //.product(name: "Glob", package: "swift-glob"),
      ],
      exclude: [
        "generate/README.md",
        "parse/README.md"
      ]
      //swiftSettings: [.unsafeFlags([
      //    "-Xfrontend",
      //    "-warn-long-function-bodies=100",
      //    "-Xfrontend",
      //    "-warn-long-expression-type-checking=50",
      //])]
      //cSettings: settings.0,
      //linkerSettings: settings.1
      //  CSetting.unsafeFlags(["-I/usr/local/Cellar/llvm/17.0.1/include"]),
      //  CSetting.define("__STDC_CONSTANT_MACROS"),
      //  CSetting.define("__STDC_FORMAT_MACROS"),
      //  CSetting.define("__STDC_LIMIT_MACROS"),
      //  CSetting.unsafeFlags(["-Wl,-search_paths_first"]),
      //  CSetting.unsafeFlags(["-Wl,-headerpad_max_install_names"])
      //]
    ),
    .target(
      name: "OctoIO"
    ),
    .systemLibrary(
      name: "clang_c",
      providers: [.brew(["llvm"])]
    ),
    .target(
      name: "Clang",
      dependencies: ["clang_c"]
      //plugins: [
      //  "ClangCGenPlugin"
      //]
    ),
    //.executableTarget(
    //  name: "CodeGenerator",
    //  exclude: ["README.md"]
    //),
    //.plugin(
    //  name: "ClangCGenPlugin",
    //  capability: .buildTool(),
    //  dependencies: ["CodeGenerator"]
    //)
  ]
)
