require "encoding_name"
require "http/headers"

struct HtmlUnicoder
  @@default_encoding : String?

  def self.default_encoding
    @@default_encoding ||= "UTF-8"
  end

  def self.default_encoding=(de : String)
    @@default_encoding = unify_encoding(de)
  end

  @io : IO

  def initialize(io : String | IO, @headers : Array(String) | HTTP::Headers | Nil = nil, @encoding : String? = nil)
    @external_io = io
    @io = if io.is_a?(String)
      MemoryIO.new(io)
    else
      io
    end
  end

  @extracted_encoding : Tuple(String, Symbol)?

  def encoding
    @extracted_encoding ||= extract_encoding
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
        if ct = headers["Content-Type"]?
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
      # TODO: rewrite this not to read all, too slow
      content = external_io.gets_to_end
      encs = extract_from_meta(content)
      @io = MemoryIO.new(content)
      encs.each do |enc1|
        if enc2 = unify_encoding(enc1)
          return {enc2, :meta}
        end
      end    
    end

    # use default encoding
    if enc = HtmlUnicoder.default_encoding
      return {enc, :default}
    end

    # last crazy impossible case,
    #   when default encoding was not set correctly
    {"UTF-8", :default}
  end

  # result io
  def io
    enc = encoding[0]
    io = @io
    io.set_encoding(enc, invalid: :skip)
    io
  end

  def to_s
    io.gets_to_end
  end

  private def unify_encoding(enc : String) : String?
    HtmlUnicoder.unify_encoding(enc)
  end

  protected def self.unify_encoding(enc : String) : String?
    EncodingName.new(enc, true).normalize
  end

  HEADERS_REGX = %r{content-type:\s*.+?charset\s*=\s*["']?(.+?)["']?$}i
  META_REGX = %r{<meta([^>]*)>}mi
  CHARSET_REGX = %r{[^<]*charset=['"\s]?(.+?)([;'"\s>]|\z)}im
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
