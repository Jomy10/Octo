require 'colorize'
require 'sem_version'

# Cross-platform way of finding an executable in the $PATH.
#
#   which('ruby') #=> /usr/bin/ruby
#
# See: https://stackoverflow.com/a/5471032/14874405
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

# Find the location of a brew package
def brew_find_pkg name
  return nil if which("brew").nil?

  versions = `brew list --versions "#{name}"`
  abort "Couldn't find #{name} through brew" unless $?.to_i == 0
  cellar_path = `brew --cellar`

  versions = versions.split("\n")
    .map { |line|
      line.split(" ")
    }.filter { |s|
      if s.count != 2
        puts "[WARNING] #{s}".yellow
      end

      next s.count == 2
    }.map { |el| el[1] }

  abort("No installed versions of #{name} found using homebrew") if versions.count == 0

  latest_version = versions.inject(nil) do |res, el|
    version = SemVersion.new(el)

    next version if res == nil
    next version > res ? version : res
  end

  bin_path = File.join(cellar_path.strip, name, latest_version.to_s)

  abort "#{bin_path} doesn't exist" unless File.exist?(bin_path)

  return bin_path
end

# Find the location of the `llvm-config` executable
def llvm_config
  ENV["LLVM_CONFIG_PATH"] || which("llvm-config") || File.join(brew_find_pkg("llvm"), "/bin/llvm-config")
end
