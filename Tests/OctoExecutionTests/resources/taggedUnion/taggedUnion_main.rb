require_relative '../testing.rb'
require_relative '../../../../.build/tests/taggedUnion.rb'

tester = Tester.new

tu_value = TaggedUnion::TU_Value.new(stringvalue: "Hello world")
tu = TaggedUnion::MyTaggedUnion.new(type: :STRING, value: tu_value)

tester.assertEq(tu.value, "Hello world")
tester.assertEq(tu.value, tu_value.stringvalue)
tester.assertEq(tu.type, :STRING)

tu2 = TaggedUnion.createStringValue("Hello world")

tester.assertEq(tu2.type, :STRING)
tester.assertEq(tu2.value, "Hello world")

tui_value = TaggedUnion::TU_Value.new(intvalue: 42)
tui = TaggedUnion::MyTaggedUnion.new(type: :INTEGER, value: tui_value)

tester.assertEq(tui.type, :INTEGER)
tester.assertEq(tui.value, 42)
tester.assertEq(tui_value.intvalue, tui.value)

puts tester.json
