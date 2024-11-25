require_relative '../testing.rb'
require_relative '../../../../.build/tests/initSelfParam.rb'

tester = Tester.new

ms = InitSelfParam::MyStruct.new(a: 69)
tester.assertEq(ms.a, 69)

puts tester.json
