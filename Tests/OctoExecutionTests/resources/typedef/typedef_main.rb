require_relative '../testing.rb'
require_relative '../../../../.build/tests/typedef.rb'

tester = Tester.new

a = Typedef::MyStruct.new(1)
b = Typedef::TheStruct.new(1)
c = Typedef::ThePointer.new(1)

tester.assert(Typedef::fn("abc", a, b, c))
tester.assertEq(Typedef::MyStruct.value, 5)
tester.assertEq(Typedef::TheStruct.value, 5)
tester.assertEq(Typedef::ThePointer.value, 5)
tester.assertEq(Typedef::MyStruct2.value, 6)

tester.assertEq(a.id, 1)
tester.assertEq(b.id, 1)
tester.assertEq(c.id, 1)

puts tester.json
