class HtmlUnicoder::IOWrapper < IO
  def initialize(head : Bytes, @remained : IO)
    @head = true
    @mio = IO::Memory.new(head)
  end

  def read(slice : Slice(UInt8))
    if @head
      count = @mio.read(slice)
      if count == 0 && slice.size != 0
        @head = false
        @remained.read(slice)
      else
        count
      end
    else
      @remained.read(slice)
    end
  end

  def write(slice : Slice(UInt8))
    raise "not implemented"
  end

  def rewind
    @head = true
    @mio.rewind
    @remained.rewind
  end
end
