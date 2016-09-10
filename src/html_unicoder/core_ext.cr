module IO::Buffered
  def rewind_buffer(size : Int32)
    new_buf = @in_buffer_rem.to_unsafe - size
    new_size = @in_buffer_rem.size + size
    if new_buf >= in_buffer
      @in_buffer_rem = Slice.new(new_buf, new_size)
    else
      raise "invalid shift"
    end
  end
end
