require 'os'
require 'colorize'
require_relative './build-utils.rb'

# Package paths
EXPRESSION_INTERPRETER_PKG = "Sources/ExpressionInterpreter"

def exec(cmd, context)
  puts cmd.grey
  system cmd
  abort("error while compiling #{context}") unless $?.to_i == 0
end

packages = []
swiftMode = :build

case ARGV[0]
when "all"
  packages << :ExpressionInterpreter
  packages << :Octo
when "ExpressionInterpreter"
  packages << :ExpressionInterpreter
when "Octo"
  packages << :Octo
when "test"
  packages << :Octo
  swiftMode = :test
when nil
  packages << :ExpressionInterpreter
  packages << :Octo
else
  raise "Invalid argument #{ARGV[0]}"
end

mode = ARGV[1] || "debug"

for package in packages
  puts "Building package #{package}...".blue
  case package
  when :Octo
    # libclang
    flags = `#{llvm_config} --cflags --ldflags --libs --system-libs`.split(" ")

    flags = flags
      .map do |flag|
        if flag[1] == "l" || flag[1] == "L"
          next "-Xlinker #{flag}"
        elsif flag[1] == "W"
          next ""
        else
          next "-Xcc #{flag}"
        end
      end

    unless OS.mac? # manually link instead of the xcframework
      flags << "-Xswiftc -L#{EXPRESSION_INTERPRETER_PKG}/target/#{mode}"
      flags << "-Xswiftc -lExpressionInterpreter"
    end

    flags = flags.filter { |v| v != "" }

    case swiftMode
    when :build
      exec "swift build -c #{mode} #{flags.join(" ")}", package
    when :test
      exec "swift test #{flags.join(" ")} #{ARGV[1] ? "--filter #{ARGV[1]}" : ""}", "tests"
    else
      raise "Invalid swiftMode #{swiftMode}"
    end
  when :ExpressionInterpreter
    Dir.chdir(EXPRESSION_INTERPRETER_PKG) do
      if OS.mac?
        exec "cargo swift package -n ExpressionInterpreter -p macos #{mode == "release" ? "--release" : ""}", package
      else
        exec "cargo build +nightly --#{mode}", package
        exec "cargo +nightly run --bin uniffi-bindgen generate src/lib.udl --language swift --out-dir generated"
        exec "mkdir ExpressionInterpreter"
        exec "mv generated/ExpressionInterpreter.swift ExpressionInterpreter/ExpressionInterpreter.swift"
        exec "mv generated/ExpressionInterpreterFFI.modulemap generated/module.modulemap"
      end
    end
  else
    abort "Unknown package #{package}"
  end
end
