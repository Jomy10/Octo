flags = `/usr/local/Cellar/llvm/17.0.1/bin/llvm-config --cflags --ldflags --libs --system-libs`.split(" ")
#umbrella header "clang.h"


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

system "swift build -c debug #{flags.join(" ")}"

abort("Error while compiling") unless $?.to_i == 0
