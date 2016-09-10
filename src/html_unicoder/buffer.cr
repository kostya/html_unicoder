require "io"

class HtmlUnicoder::Buffer
  include IO::Buffered

  @io : IO

  def initialize(@io)
  end

  private def unbuffered_read(slice : Slice(UInt8))
    @io.read(slice)
  end

  private def unbuffered_write(slice : Slice(UInt8))
    @io.write(slice)
  end

  private def unbuffered_close
    @io.close
  end

  private def unbuffered_rewind
    @io.rewind
  end

  private def unbuffered_flush
    @io.flush
  end
end
