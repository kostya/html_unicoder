require "spec"
require "../src/html_unicoder"
require "base64"

def str(array)
  String.new(array.to_unsafe, array.size)
end

def fixture(name)
  File.read("#{__DIR__}/fixtures/#{name}")
end

EMPTY = [] of String

Spec.before_each do
  HtmlUnicoder.default_encoding = ""
end
