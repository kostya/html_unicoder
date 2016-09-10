require "encoding_name"
# require "http/headers"

# unicoder = HtmlUnicoder.new(page)
# unicoder.io.gets_to_end

# unicoder = HtmlUnicoder.new(page, headers: headers)
# unicoder.io.gets_to_end

# unicoder = HtmlUnicoder.new(page, encoding: "CP1251")
# unicoder.io.gets_to_end

class HtmlUnicoder
  @@default_encoding : String?

  def self.default_encoding
    @@default_encoding ||= "UTF-8"
  end

  def self.default_encoding=(de : String)
    @@default_encoding = unify_encoding(de)
  end

  # TODO: 
  #   * add io as IO, headers as HTTP::Headers
  #   * add @header : String? = nil

  def initialize(@io : String, @headers : Array(String) | Nil = nil, @encoding : String? = nil)
    @result_io = MemoryIO.new(@io)
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
      encs = extract_from_headers(headers)
      encs.each do |enc1|
        if enc2 = unify_encoding(enc1)
          return {enc2, :headers}
        end
      end
    end

    # find encoding in meta from page
    encs = extract_from_meta(@io)
    encs.each do |enc1|
      if enc2 = unify_encoding(enc1)
        return {enc2, :meta}
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
    io = @result_io
    io.set_encoding(encoding[0], invalid: :skip)
    io
  end

  def to_s
    io.gets_to_end
  end

  private def unify_encoding(enc : String) : String?
    EncodingName.new(enc, true).normalize
  end

  private def self.unify_encoding(enc : String) : String?
    EncodingName.new(enc, true).normalize
  end

  HEADERS_REGX = %r{content-type:\s*.+?charset\s*=\s*["']?(.+?)["']?$}i
  META_REGX = %r{<meta([^>]*)>}mi
  CHARSET_REGX = %r{[^<]*charset=['"\s]?(.+?)([;'"\s>]|\z)}im

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