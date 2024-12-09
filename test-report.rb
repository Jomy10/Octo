# Output a prettier test report + create a report per language and the supported features
# requires "xcpretty" to be installed: `gem install xcpretty`

require 'rexml/document'
require 'colorize'

puts "== Generating test report ==".blue

oldFiles = Dir[".build/tests/*.xml"]
oldFiles.each do |fileName|
  File.delete(fileName)
end

cmd = "TEST_REPORT=1 ruby build.rb test"
puts cmd.grey
system cmd

def loop_child(child, out)
  case child.name
  when "testsuites"
    out[child[:name]] = {
      testCount: child[:tests].to_i,
      failures: child[:failures].to_i,
      testSuiteGroups: Hash.new
    }
    v = out[child[:name]]
    for child in child.children.filter { |e| e.is_a? REXML::Element }
      loop_child(child, v[:testSuiteGroups])
    end
  when "testsuite"
    fullname = child[:name]
    split = fullname.split(".")
    group = split[0]
    name = split[1]
    if out[group] == nil
      out[group] = {
        totalCount: -1,
        totalFailures: -1,
        testSuites: []
      }
    end
    out[group][:testSuites] << {
      name: name,
      testCount: child[:tests].to_i,
      failures: child[:failures].to_i,
      testCases: Hash.new
    }

    for child in child.children.filter { |e| e.is_a? REXML::Element }
      loop_child(child, out[group][:testSuites].last[:testCases])
    end
  when "testcase"
    if out[child[:name]] == nil
      out[child[:name]] = {
        time: child[:time],
        failures: []
      }
    end

    testCaseEntry = out[child[:name]]
    for child in child.children.filter { |e| e.is_a? REXML::Element }
      loop_child(child, testCaseEntry[:failures])
    end
  when "failure"
    out << {
      message: child[:message],
      location: child.get_text.value
    }
  else
    raise child.name + " unexpected"
  end
end

files = Dir[".build/tests/*.xml"].map { |f| File.new(f) }
out = Hash.new

for file in files
  doc = REXML::Document.new(file)

  for child in doc.children.filter { |e| e.is_a? REXML::Element }
    loop_child(child, out)
  end
end

def formatCounts(count, failures)
  "#{count} tests, #{(lambda {
      s = "#{failures} failures"
      if failures != 0
        s = s.red
      end
      return s
    }).call}"
end

def formatTestCase(name, testCase)
  if testCase[:failures].count == 0
    name = name.green
  else
    name = name.red
  end
  time = testCase[:time]
  if time == nil
    time = ""
  else
    time = " #{time}s"
  end

  return "#{name}#{time}"
end

for _, testSuiteData in out
  for _, testSuiteGroupData in testSuiteData[:testSuiteGroups]
    testSuiteGroupData[:totalCount] = testSuiteGroupData[:testSuites].map { |s| s[:testCount] }.sum
    testSuiteGroupData[:totalFailures] = testSuiteGroupData[:testSuites].map { |s| s[:failures] }.sum
  end
end

for name, testSuiteData in out
  puts "#{name.blue}: #{formatCounts(testSuiteData[:testCount], testSuiteData[:failures])}"
  for testSuiteGroupName, testSuiteGroupData in testSuiteData[:testSuiteGroups]
    puts "  #{testSuiteGroupName.cyan}: #{formatCounts(testSuiteGroupData[:totalCount], testSuiteGroupData[:totalFailures])}"
    for testSuite in testSuiteGroupData[:testSuites]
      puts "    #{testSuite[:name].yellow}: #{formatCounts(testSuite[:testCount], testSuite[:failures])}"
      for testCaseName, testCaseData in testSuite[:testCases]
        puts "      #{formatTestCase(testCaseName, testCaseData)}"
        for failure in testCaseData[:failures]
          puts "        #{failure[:location]}"
          puts "          #{failure[:message]}".red
        end
      end
    end
  end
end

def determineLang(testCaseName)
  return :ruby if testCaseName.include?("Ruby")
  return :swift if testCaseName.include?("Swift")
  return :rust if testCaseName.include?("Rust")
  return :cxx if testCaseName.include?("Cxx")
  return :c if testCaseName.include?("C")
  raise "Unhandled language for #{testCaseName}"
end

def determineFeatureName(testCaseName)
  return :attach if testCaseName.include?("Adder")
  return :enums if testCaseName.include?("Enum")
  return :selfParams if testCaseName.include?("SelfParam")
  return :taggedUnions if testCaseName.include?("TaggedUnion")
  return :typedefs if testCaseName.include?("Typedef")
  raise "Unhandled feature for #{testCaseName}"
end

language_support = Hash.new

testSuiteGroup = out["OctoPackageTests.xctest"][:testSuiteGroups]["OctoExecutionTests"]
for testSuite in testSuiteGroup[:testSuites]
  for testCaseName, testCaseData in testSuite[:testCases]
    lang = determineLang(testCaseName)
    language_support[lang] = [] if language_support[lang] == nil
    language_support[determineLang(testCaseName)] << {
      feature: determineFeatureName(testCaseName),
      support: testCaseData[:failures].count == 0
    }
  end
end

puts "\nUnsupported features per target language:".yellow
for language, features in language_support
  unsupported_features = features.find_all { |feature| !feature[:support] }
  msg = ""
  if unsupported_features.count == 0
    msg << language.to_s.green
  else
    msg << language.to_s.red + ":"
  end
  for unsupported_feature in unsupported_features
    msg << " " + unsupported_feature[:feature].to_s
  end
  puts msg
end
