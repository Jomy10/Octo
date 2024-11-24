require_relative '../testing.rb'
require_relative '../../../../.build/tests/adder.rb'

tester = Tester.new

adder = Adder::Adder.new(1, 2)

tester.assertEq(adder.lhs, 1)
tester.assertEq(adder.rhs, 2)
tester.assertEq(adder.add, 1 + 2)

adder.lhs = 5

tester.assertEq(adder.add, 5 + 2)

puts tester.json
