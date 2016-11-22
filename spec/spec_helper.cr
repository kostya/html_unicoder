require "spec"
require "../src/html_unicoder"
require "base64"
require "http"
require "crypto/md5"

def md5(str)
  Crypto::MD5.hex_digest(str)
end

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

# This is a non-optimized version of IO::Memory so we can test
# raw IO. Optimizations for specific IOs are tested separately
# (for example in buffered_io_spec)
class SimpleIO::Memory
  include IO

  getter buffer : UInt8*
  getter bytesize : Int32
  @capacity : Int32
  @pos : Int32
  @max_read : Int32?

  def initialize(capacity = 64, @max_read = nil)
    @buffer = GC.malloc_atomic(capacity.to_u32).as(UInt8*)
    @bytesize = 0
    @capacity = capacity
    @pos = 0
  end

  def self.new(string : String, max_read = nil)
    io = new(string.bytesize, max_read: max_read)
    io << string
    io
  end

  def self.new(bytes : Slice(UInt8), max_read = nil)
    io = new(bytes.size, max_read: max_read)
    io.write(bytes)
    io
  end

  def read(slice : Slice(UInt8))
    count = slice.size
    count = Math.min(count, @bytesize - @pos)
    if max_read = @max_read
      count = Math.min(count, max_read)
    end
    slice.copy_from(@buffer + @pos, count)
    @pos += count
    count
  end

  def write(slice : Slice(UInt8))
    count = slice.size
    new_bytesize = bytesize + count
    if new_bytesize > @capacity
      resize_to_capacity(Math.pw2ceil(new_bytesize))
    end

    slice.copy_to(@buffer + @bytesize, count)
    @bytesize += count

    nil
  end

  def to_slice
    Slice.new(@buffer, @bytesize)
  end

  private def check_needs_resize
    resize_to_capacity(@capacity * 2) if @bytesize == @capacity
  end

  private def resize_to_capacity(capacity)
    @capacity = capacity
    @buffer = @buffer.realloc(@capacity)
  end
end
