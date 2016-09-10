require "./spec_helper"

describe HtmlUnicoder do
  context "extract_encoding" do
    it "extract from headers" do
      HtmlUnicoder.new("текст", ["Content-type: text/html; charset=UTF-8"]).encoding.should eq({"UTF-8", :headers})
      HtmlUnicoder.new("текст", ["Content-type: text/html; charset=utf-8"]).encoding.should eq({"UTF-8", :headers})
      HtmlUnicoder.new("текст", ["Content-type: text/html; charset=Windows-1251"]).encoding.should eq({"WINDOWS-1251", :headers})
      HtmlUnicoder.new("текст", ["Content-type: text/html; charset=koi8r"]).encoding.should eq({"KOI8-R", :headers})

      HtmlUnicoder.new("текст", hh ["Content-type: text/html; charset=UTF-8"]).encoding.should eq({"UTF-8", :headers})
      HtmlUnicoder.new("текст", hh ["Content-type: text/html; charset=utf-8"]).encoding.should eq({"UTF-8", :headers})
      HtmlUnicoder.new("текст", hh ["content-type: text/html; charset=Windows-1251"]).encoding.should eq({"WINDOWS-1251", :headers})
      HtmlUnicoder.new("текст", hh ["Content-type: text/html; charset=koi8r"]).encoding.should eq({"KOI8-R", :headers})
    end

    it "extract from meta" do
      page = %{<head><meta charset="windows-1251"></head>текст}
      HtmlUnicoder.new(page, EMPTY).encoding.should eq({"WINDOWS-1251", :meta})

      page = %{<head><meta charset="utf8"></head>текст}
      HtmlUnicoder.new(page, EMPTY).encoding.should eq({"UTF8", :meta})

      page = %{<head><meta charset=koi8r></head>текст}
      HtmlUnicoder.new(page, EMPTY).encoding.should eq({"KOI8-R", :meta})
    end

    it "extract from both" do
      page = %{<head><meta charset="windows-1251"></head>текст}
      headers = ["Content-type: text/html; charset=UTF-8"]
      HtmlUnicoder.new(page, headers).encoding.should eq({"UTF-8", :headers})
      HtmlUnicoder.new(page, hh headers).encoding.should eq({"UTF-8", :headers})

      page = %{<head><meta charset="utf-8"></head>текст}
      headers = ["Content-type: text/html; charset=windows-1251"]
      HtmlUnicoder.new(page, headers).encoding.should eq({"WINDOWS-1251", :headers})
      HtmlUnicoder.new(page, hh headers).encoding.should eq({"WINDOWS-1251", :headers})

      page = %{<head><meta charset="us-ascii"></head>текст}
      headers = ["Content-type: text/html; charset=FUT-8"]
      HtmlUnicoder.new(page, headers).encoding.should eq({"US-ASCII", :meta})
      HtmlUnicoder.new(page, hh headers).encoding.should eq({"US-ASCII", :meta})

      page = %{<head><meta charset="us-ascii"></head>текст}
      headers = ["Content-type: text/html; charset=FUT-8"]
      HtmlUnicoder.new(page, headers, encoding: "CP1251").encoding.should eq({"CP1251", :direct})
      HtmlUnicoder.new(page, hh(headers), encoding: "CP1251").encoding.should eq({"CP1251", :direct})
    end

    it "extract hard encodings" do
      HtmlUnicoder.new("текст", ["Content-type: text/html; charset=Unicode"]).encoding.should eq({"UTF-8", :headers})
      HtmlUnicoder.new("текст", ["Content-type: text/html; charset=ANSI"]).encoding.should eq({"ISO-8859-1", :headers})
      HtmlUnicoder.new("текст", ["Content-type: text/html; charset=Windows-1251;ref"]).encoding.should eq({"WINDOWS-1251", :headers})
      HtmlUnicoder.new("текст", ["Content-type: text/html; charset=Windows-1251&ref"]).encoding.should eq({"WINDOWS-1251", :headers})

      HtmlUnicoder.new("текст", hh ["Content-type: text/html; charset=Unicode"]).encoding.should eq({"UTF-8", :headers})
      HtmlUnicoder.new("текст", hh ["Content-type: text/html; charset=ANSI"]).encoding.should eq({"ISO-8859-1", :headers})
      HtmlUnicoder.new("текст", hh ["Content-type: text/html; charset=Windows-1251;ref"]).encoding.should eq({"WINDOWS-1251", :headers})
      HtmlUnicoder.new("текст", hh ["Content-type: text/html; charset=Windows-1251&ref"]).encoding.should eq({"WINDOWS-1251", :headers})
    end

    context "default_encoding" do
      it "when even not set default, is UTF-8" do
        HtmlUnicoder.new("текст", EMPTY).encoding.should eq({"UTF-8", :default})
      end

      it "set default" do
        HtmlUnicoder.default_encoding = "CP1251"
        HtmlUnicoder.new("текст", EMPTY).encoding.should eq({"CP1251", :default})
      end

      it "set default incorrectly" do
        HtmlUnicoder.default_encoding = "asdfadsf"
        HtmlUnicoder.new("текст", EMPTY).encoding.should eq({"UTF-8", :default})
      end
    end
  end
end
