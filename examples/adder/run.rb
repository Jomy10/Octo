require 'os'

# 1. Build the C library as a dynamic library
system "clang #{OS.mac? ? '-dynamiclib' : '-shared'} adder.c -o libadder.#{OS.mac? ? 'dylib' : 'so'}"
abort("Error while compiling library") unless $?.to_i == 0

# 2. Generate biindigns in ruby/adderLib.rb
# -i = header file to generate bindings for
# -n = output library name (module name in Ruby)
# -l = lbrary to link against (in this case the adder library we compiled in 1.)
# -o = output location of the bindings
system("../../.build/debug/Brooklyn --from c --to ruby -i 'adder.h' -n Adder -l adder -o ruby/adderLib.rb")
abort("Error while generating ruby bridging code") unless $?.to_i == 0

# 3. Run our program using the bindings
system("LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH:#{__dir__}\" ruby ruby/adder.rb")
abort("Error while running ruby program") unless $?.to_i == 0
