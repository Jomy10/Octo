require_relative './cJSON.rb'

json = CJSON::CJSON.Parse("{'a': 'b', 'c': 3, 'd': { 'f': [1, 2, 'e'] }}")

puts json.Print
