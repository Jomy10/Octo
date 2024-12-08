require 'os'
require 'colorize'
require_relative './build-utils.rb'

# Package paths
EXPRESSION_INTERPRETER_PKG = File.realpath("Sources/ExpressionInterpreter")

packages = []
swiftMode = :build

case ARGV[0]
when "all", nil
  packages << :ExpressionInterpreter
  packages << :SharedLibraries
  packages << :octo
  packages << :CParser
when "Octo"
  packages << :ExpressionInterpreter
  packages << :SharedLibraries
  packages << :octo
when "SharedLibraries"
  packages << :SharedLibraries
when "CLI"
  packages << :octo
when "test"
  packages << :octo
  packages << :SharedLibraries
  swiftMode = :test
when "clean"
  exec "cargo clean", "cleaning cargo workspace"
  exec "swift package clean", "cleaning swift package"
else
  packages << ARGV[0].to_sym
  # raise "Invalid argument #{ARGV[0]}"
end

mode = ARGV[1] || "debug"

for package in packages
  puts "Building package #{package}...".blue
  case package
  when :octo
    flags = []
    unless OS.mac? # manually link instead of the xcframework
      flags << "-Xswiftc -L#{EXPRESSION_INTERPRETER_PKG}/target/#{mode}"
      flags << "-Xswiftc -lExpressionInterpreter"
    end

    flags << "-Xswiftc -DOCTO_DEBUGINFO"

    for arg in (ARGV[2..] || [])
      flags << arg
    end

    # flags << "-Xlinker -L#{File.realpath ".build/#{mode}"}"

    # case package
    # when :OctoParseTypes
    #   flags << "-Xlinker -l"
    # end

    product = package.to_s
    case swiftMode
    when :build
      exec "swift build -c #{mode} #{flags.join(" ")} --product #{product} --cache-path .build/checkouts/", package
    when :test
      exec "swift test #{flags.join(" ")} #{ARGV[1] ? "--filter #{ARGV[1]}" : ""} --xunit-output=.build/tests/xunit.xml --cache-path .build/checkouts/", "tests"
    else
      raise "Invalid swiftMode #{swiftMode}"
    end
  when :SharedLibraries, :OctoIntermediate, :OctoParseTypes, :OctoConfigKeys, :Memory, :OctoIO
    extra_args = ARGV[2..] || []

    product = package.to_s
    if product == "SharedLibraries"
      product = "all"
    end

    case swiftMode
    when :build
      exec "ruby SharedLibraries/build.rb #{product} #{mode} #{extra_args.join(" ")}", product
      # exec "swift build -c #{mode} #{flags.join(" ")} #{product == nil ? "" : "--product #{product}"} --package-path SharedLibraries --cache-path .build/checkouts/ --scratch-path .build", package
    when :test
      exec "ruby SharedLibraries/build.rb test #{mode} #{extra_args.join(" ")}", "test"
      # exec "swift test #{flags.join(" ")} #{ARGV[1] ? "--filter #{ARGV[1]}" : ""} --xunit-output=../.build/tests/xunitSharedLibraries.xml -package-path SharedLibraries --cache-path .build/checkouts/ --scratch-path .build", "tests"
    end
  when :CParser
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

    flags = flags.filter { |v| v != "" }

    for arg in (ARGV[2..] || [])
      flags << arg
    end

    product = package.to_s
    exec "swift build -c #{mode} #{flags.join(" ")} --product #{product} --package-path OctoPlugins --cache-path .build/checkouts/ --scratch-path .build", package
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
