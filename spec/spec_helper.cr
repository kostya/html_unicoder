require "spec"
require "../src/html_unicoder"
require "base64"
require "http"

def str(array)
  String.new(array.to_unsafe, array.size)
end

def fixture(name)
  File.read("#{__DIR__}/fixtures/#{name}")
end

def fixture_io(name)
  File.open("#{__DIR__}/fixtures/#{name}", "r")
end

EMPTY = [] of String

Spec.before_each do
  HtmlUnicoder.default_encoding = ""
end

def hh(array)
  h = HTTP::Headers.new
  array.each do |line|
    k, v = HTTP.parse_header(line)
    h.add k, v
  end
  h
end