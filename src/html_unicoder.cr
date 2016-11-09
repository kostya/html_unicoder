require "encoding_name"
require "http/headers"

struct HtmlUnicoder
end

require "./html_unicoder/*"

struct HtmlUnicoder
  @@default_encoding : String?

  DEFAULT_ENCODING = "UTF-8"
  CONTENT_TYPE     = "Content-Type"

  def self.default_encoding
    @@default_encoding
  end

  def self.default_encoding=(de : String)
    @@default_encoding = unify_encoding(de)
  end

  @io : IO

  def initialize(io : String | IO, @headers : Array(String) | HTTP::Headers | Nil = nil, @encoding : String? = nil, @default_encoding : String? = nil)
    @external_io = io
    @io = if io.is_a?(String)
            MemoryIO.new(io)
          else
            io
          end
    @extracted_encoding_flag = false
  end

  @extracted_encoding : Tuple(String, Symbol)?
  @extracted_encoding_flag : Bool

  def encoding
    if @extracted_encoding_flag
      @extracted_encoding
    else
      @extracted_encoding_flag = true
      @extracted_encoding = extract_encoding
    end
  end

  # extract encoding from data
  private def extract_encoding
    # find encoding in param
    if (enc1 = @encoding) && (enc2 = unify_encoding(enc1))
      return {enc2, :direct}
    end

    # find encoding in header
    if headers = @headers
      if headers.is_a?(Array)
        encs = extract_from_headers(headers)
        encs.each do |enc1|
          if enc2 = unify_encoding(enc1)
            return {enc2, :headers}
          end
        end
      else
        if ct = headers[CONTENT_TYPE]?
          if ct =~ CHARSET_REGX2
            encs = $1.to_s.split(';')
            encs.each do |enc1|
              if enc2 = unify_encoding(enc1)
                return {enc2, :headers}
              end
            end
          end
        end
      end
    end

    # find encoding in meta from page

    external_io = @external_io

    if external_io.is_a?(String)
      encs = extract_from_meta(external_io)
      encs.each do |enc1|
        if enc2 = unify_encoding(enc1)
          return {enc2, :meta}
        end
      end
    else
      buf = uninitialized UInt8[BUFFER_SIZE]
      slice = buf.to_slice
      size = external_io.read(slice)
      head = String.new(slice.to_unsafe, size)
      encs = extract_from_meta(head)

      @io = HtmlUnicoder::IOWrapper.new(head.to_slice, external_io)

      encs.each do |enc1|
        if enc2 = unify_encoding(enc1)
          return {enc2, :meta}
        end
      end
    end

    # use default encoding
    if (enc = @default_encoding) && (enc2 = unify_encoding(enc))
      return {enc2, :default}
    end

    # use default encoding
    if enc = HtmlUnicoder.default_encoding
      return {enc, :default}
    end
  end

  BUFFER_SIZE = 6 * 1024

  # result io
  def io
    if enc = encoding
      io = @io
      io.set_encoding(enc[0], invalid: :skip)
      io
    else
      @io
    end
  end

  @result : String?

  def to_s
    @result ||= io.gets_to_end
  end

  private def unify_encoding(enc : String) : String?
    HtmlUnicoder.unify_encoding(enc)
  end

  protected def self.unify_encoding(enc : String) : String?
    EncodingName.new(enc, true).normalize
  end

  HEADERS_REGX  = %r{content-type:\s*.+?charset\s*=\s*["']?(.+?)["']?$}i
  META_REGX     = %r{<meta([^>]*)>}mi
  CHARSET_REGX  = %r{[^<]*charset=['"\s]?(.+?)([;'"\s>]|\z)}im
  CHARSET_REGX2 = %r{charset\s*=\s*["']?(.+?)["']?$}i

  private def extract_from_headers(headers : Array(String))
    encodings = [] of String
    headers.each do |header|
      if header =~ HEADERS_REGX
        encodings += $1.to_s.split(';')
      end
    end
    encodings
  end

  private def extract_from_meta(content)
    encodings = [] of String
    content.scan(META_REGX) do |res|
      if str = res[1]?
        match = str.match(CHARSET_REGX)
        if match && (enc = match[1]?)
          encodings << enc
        end
      end
    end
    encodings
  end
end
