require_relative '../testing.rb'
require_relative '../../../../.build/tests/enums.rb'

tester = Tester.new

tester.assert(EnumTest::LogLevel.visible(:INFO), "LogLevel :INFO not shown as visible")
tester.assert(!EnumTest::LogLevel.visible(:TRACE), "LogLevel :TRACE shown as visible")

EnumTest::LogLevel.setLogLevel(:TRACE)
tester.assert(EnumTest::LogLevel.visible(:TRACE), "LogLevel :TRACE not shown as visible")

puts tester.json
