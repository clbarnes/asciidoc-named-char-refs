#!/usr/bin/env ruby
require 'json'
require 'net/http'

ENTITIES_URL = "https://www.w3.org/TR/html52/entities.json"
DEFAULT_PATH = "character_refs.adoc"

def strip_outer(s)
  s = s.gsub(/;$/, "")
  s.gsub!(/^&/, "")
end

def mangle_name(s)
  s = strip_outer(s)
  s.gsub(/[A-Z]+/) {|caps| "_#{caps}_"}
end

def make_attr(mangled_name, codepoint)
  ":#{mangled_name}-: &\##{codepoint};"
end

response = Net::HTTP.get(URI(ENTITIES_URL))
data = JSON.parse(response)

rows = data
  .map
  .reject{|name, _| !name.end_with?(";")}
  .reduce([]){
    |arr, (name, d)|
    codepoint = d["codepoints"][0]
    lower_name = name.downcase
    if lower_name != name and !data.key?(lower_name)
      arr << make_attr(mangle_name(lower_name), codepoint)
    end
    arr << make_attr(mangle_name(name), codepoint)
    arr
  }

# puts rows

path = ARGV.length >= 1 ? ARGV[0] : DEFAULT_PATH

File.open(path, "w") do |file|
  rows.each{|row| file << row << "\n"}
end
