require 'json'

# Testing framework for ruby which can be parsed again in Swift tests

class Tester
  def initialize
    @testAssertions = []
  end

  def assert condition, msg = ""
    @testAssertions << Assertion.new(
      caller_locations.first.path,
      condition,
      msg
    )
  end

  def assertEq a, b
    @testAssertions << Assertion.new(
      caller_locations.first.path,
      a == b,
      "'#{a}' != '#{b}'"
    )
  end

  def json
    return { assertions: @testAssertions.map { |e| e.to_h } }.to_json
  end
end

Assertion = Struct.new(:path, :success, :msgOnError)
