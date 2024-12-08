require_relative "../build-utils.rb"

Dir.chdir(__dir__)

mode = ARGV[1] || "debug"
swiftMode = "build"

products = []

def allProducts
  products = []
  products << :OctoMemory
  products << :OctoIO
  products << :OctoConfigKeys
  products << :OctoIntermediate
  products << :OctoParseTypes
  return products
end

case ARGV[0]
when "test"
  swiftMode = "test"
  products = allProducts
when "all", nil
  products = allProducts
else
  products << ARGV[0]
end

flags = ["-Xswiftc -DOCTO_DEBUGINFO"]

for arg in (ARGV[2..] || [])
  flags << arg
end

for product in products
  exec "swift #{swiftMode} -c #{mode} --package-path #{product} --cache-path ../.build/checkouts/ --scratch-path ../.build", product
end
