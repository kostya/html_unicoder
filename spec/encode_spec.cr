require "./spec_helper"

describe HtmlUnicoder do
  it "detects encoding in headers" do
    HtmlUnicoder.new("текст", ["Content-type: text/html; charset=UTF-8"]).to_s.should eq "текст"
  end

  it "detects encoding in meta" do
    page = <<-HTML
      <head><meta charset="UTF-8"></head>текст
    HTML
    HtmlUnicoder.new(page).to_s.should eq page
  end

  it "overrides charset specified in meta with charset specified in header" do
    page = <<-HTML
      <head><meta charset="windows-1251"></head>текст
    HTML
    HtmlUnicoder.new(page, ["Content-type: text/html; charset=UTF-8"]).to_s.should eq page
    HtmlUnicoder.new(page, hh ["Content-type: text/html; charset=UTF-8"]).to_s.should eq page
  end

  it "supports old meta format" do
    page = <<-HTML
      <head><meta name="Content-type" content="text/html; charset=utf-8"></head>текст
    HTML
    HtmlUnicoder.new(page).to_s.should eq page
  end

  it "supports meta in bare document" do
    page = <<-HTML
      <meta http-equiv="Content-type" content="text/html; charset=utf-8">текст
    HTML
    HtmlUnicoder.new(page).to_s.should eq page
  end

  it "falls back to default_encoding(windows-1251) if no encoding is specified" do
    HtmlUnicoder.default_encoding = "CP1251"
    HtmlUnicoder.new(str(UInt8[242, 229, 241, 242])).to_s.should eq "тест"
  end

  it "supports encoding from koi8-r" do
    HtmlUnicoder.new(str(UInt8[212, 197, 211, 212]), ["Content-type: text/html; charset=KOI8-R"]).to_s.should eq "тест"
  end

  it "supports encoding from koi8-u" do
    page = str(UInt8[245, 203, 210, 193, 167, 206, 211, 216, 203, 193, 32, 205, 207, 215, 193, 32, 206, 193, 204, 197, 214, 201, 212, 216, 32, 196, 207, 32, 166, 206, 196, 207, 164, 215, 210, 207, 208, 197, 202, 211, 216, 203, 207, 167, 32, 205, 207, 215, 206, 207, 167, 32, 210, 207, 196, 201, 206, 201])
    page_utf8 = "Українська мова належить до індоєвропейської мовної родини"
    HtmlUnicoder.new(page, ["Content-type: text/html; charset=KOI8-U"]).to_s.should eq page_utf8
    HtmlUnicoder.new(page, hh ["Content-type: text/html; charset=KOI8-U"]).to_s.should eq page_utf8
  end

  it "supports encoding iso8859-1 (latin1)" do
    HtmlUnicoder.new(str(UInt8[114, 233, 115, 117, 109, 233]), ["Content-type: text/html; charset=iso8859-1"]).to_s.should eq "résumé"
    HtmlUnicoder.new(str(UInt8[114, 233, 115, 117, 109, 233]), hh ["Content-type: text/html; charset=iso8859-1"]).to_s.should eq "résumé"
  end

  it "supports encoding windows-1252" do
    HtmlUnicoder.new(str(UInt8[114, 233, 115, 117, 109, 233]), ["Content-type: text/html; charset=windows-1252"]).to_s.should eq "résumé"
    HtmlUnicoder.new(str(UInt8[114, 233, 115, 117, 109, 233]), hh ["Content-type: text/html; charset=windows-1252"]).to_s.should eq "résumé"
  end

  it "supports encoding tis-620" do
    HtmlUnicoder.new(str(UInt8[170, 232, 210, 167, 225, 205, 195, 236]), ["Content-type: text/html; charset=tis-620"]).to_s.should eq "ช่างแอร์"
    HtmlUnicoder.new(str(UInt8[170, 232, 210, 167, 225, 205, 195, 236]), hh ["Content-type: text/html; charset=tis-620"]).to_s.should eq "ช่างแอร์"
  end

  it "supports encoding windows-874" do
    HtmlUnicoder.new(str(UInt8[188, 197, 161, 210, 195, 180, 211, 224, 185, 212, 185, 167, 210, 185]), ["Content-type: text/html; charset=windows-874"]).to_s.should eq "ผลการดำเนินงาน"
    HtmlUnicoder.new(str(UInt8[188, 197, 161, 210, 195, 180, 211, 224, 185, 212, 185, 167, 210, 185]), hh ["Content-type: text/html; charset=windows-874"]).to_s.should eq "ผลการดำเนินงาน"
  end

  it "supports > in meta tag" do
    page = <<-HTML
    <meta http-equiv="Content-type" content="text/html;> charset=utf-8">текст
    HTML
    HtmlUnicoder.new(page).to_s.should eq page
  end

  it "doesn't get confused with attributes of other tags" do
    page = <<-HTML
    <meta name="blah"> <script charset="utf8"></script>текст
    HTML
    HtmlUnicoder.new(page).encoding.should eq(nil)
  end

  it "ignores bad characters" do
    HtmlUnicoder.new(str(UInt8[116, 101, 115, 116, 242, 229, 241, 242, 116, 101, 115, 116]),
      ["Content-type: text/html;charset=UTF-8"]).to_s.should eq "testtest"
  end

  it "converts from cp1251 to utf-8" do
    HtmlUnicoder.new(str(UInt8[242, 229, 234, 241, 242]), encoding: "cp1251").to_s.should eq "текст"
  end

  it "converts from koi8-r to utf-8" do
    HtmlUnicoder.new(str(UInt8[212, 197, 203, 211, 212]), encoding: "koi8-r").to_s.should eq "текст"
  end

  it "converts for fixture" do
    page = fixture("bad_encoding.html")
    HtmlUnicoder.new(page, ["Content-Type: text/html; charset=utf-8"]).to_s # should not raise
    HtmlUnicoder.new(page).to_s                                             # should not raise
  end

  it "picks the first correct encoding from meta" do
    page = <<-HTML
      <meta http-equiv="Content-type" content="text/html; charset=CRAP">
      <meta http-equiv="Content-type" content="text/html; charset=utf-8">
      <meta http-equiv="Content-type" content="text/html; charset=cp1251">текст
    HTML
    HtmlUnicoder.new(page).to_s.should eq page
    HtmlUnicoder.new(page).encoding.should eq({"UTF-8", :meta})
  end

  it "picks encoding from meta if encoding in headers is non-existent" do
    page = <<-HTML
      <meta http-equiv="Content-type" content="text/html; charset=utf-8">текст
    HTML
    HtmlUnicoder.new(page, ["Content-Type: text/html; charset=_crap"]).to_s.should eq page
    HtmlUnicoder.new(page, ["Content-Type: text/html; charset=_crap"]).encoding.should eq({"UTF-8", :meta})
    HtmlUnicoder.new(page, hh ["Content-Type: text/html; charset=_crap"]).encoding.should eq({"UTF-8", :meta})
  end

  it "supports 'charset=utf-8; dir=rtl' in meta" do
    page = <<-HTML
      <meta http-equiv="Content-type" content="text/html; charset=utf-8; dir=rtl">текст
    HTML
    HtmlUnicoder.new(page).to_s.should eq page
    HtmlUnicoder.new(page).encoding.should eq({"UTF-8", :meta})
  end

  it "supports 'charset=utf-8; dir=rtl' in headers" do
    page = <<-HTML
      текст
    HTML
    HtmlUnicoder.new(page, ["Content-Type: text/html; charset=utf-8; dir=rtl"]).to_s.should eq page
    HtmlUnicoder.new(page, ["Content-Type: text/html; charset=utf-8; dir=rtl"]).encoding.should eq({"UTF-8", :headers})
    HtmlUnicoder.new(page, hh ["Content-Type: text/html; charset=utf-8; dir=rtl"]).encoding.should eq({"UTF-8", :headers})
  end

  it "finds the right encoding in some arbitrary html" do
    page = fixture("bad_encoding2.html")
    u = HtmlUnicoder.new(page)
    u.encoding.should eq({"WINDOWS-1251", :meta})
    page = u.to_s
    page.bytesize.should eq 99258
    page.includes?("Груздовский карьер").should eq true
  end

  it "ignores bad characters" do
    u = HtmlUnicoder.new(str(UInt8[116, 101, 115, 116, 242, 229, 241, 242, 116, 101, 115, 116]), ["Content-type: text/html; charset=unicode"])
    u.to_s.should eq "testtest"
  end

  it "bug?" do
    HtmlUnicoder.new(fixture("bug.html")).encoding.should eq({"WINDOWS-1252", :meta})
  end

  it "ignores encoding in link tags" do
    page = <<-TXT
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
      <!-- Do not change anything in this section except the title tag -->
      <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
      <meta name="keywords" content="HP, Service Manager, ServiceDesk" />
      <meta http-equiv="Content-Style-Type" content="text/css" />
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

      <meta name="generator" content="webhelp Standard 2.85 (unicode)" />
      <!-- Main title bar...you must change this...use the topic title -->

      <title>Web client and self-service tailoring options</title>
      <!-- link to hpsoftware.css and JavaScript files. Do not change -->
      <link href="../../../resources/hpsoftware.css" rel="stylesheet"
      type="text/css" charset="ISO-8859-1" />
      <meta http-equiv="Content-Style-Type" content="text/css" />

      <meta name="Product_Class" content="HP Service Manager" />
      <meta name="Version" content="7.10" />
      <script src="../../../resources/jscripts/togglediv.js" type=
      "text/javascript">
      </script>
      <link rel="stylesheet" href="/files/helpindex.css" type=
      "text/css" />

      <script type="text/JavaScript" src="/files/supply.js"></script>
      <script type="text/JavaScript">
      helptop.c2wtopf.pageid = "tailor/web_client/concepts/web_client_and_self_service_tailoring_options.htm";
      </script>

      </head>
      <body> текст </body> </html>
    TXT
    HtmlUnicoder.new(page).to_s.should eq page
    HtmlUnicoder.new(page).encoding.should eq({"UTF-8", :meta})
  end

  it "convert from bad missing encoding" do
    HtmlUnicoder.default_encoding = "UTF-8"
    HtmlUnicoder.new(Base64.decode_string("ey8qx+Tl8fwg7+Dw4Ozl8vD7IOLo5+jy4CovfQ==")).to_s.should eq "{/*  */}"
  end

  it "convert double times" do
    HtmlUnicoder.default_encoding = "UTF-8"
    str = HtmlUnicoder.new(Base64.decode_string("ey8qx+Tl8fwg7+Dw4Ozl8vD7IOLo5+jy4CovfQ==")).to_s
    str.should eq "{/*  */}"
    str = HtmlUnicoder.new(str).to_s
    str.should eq "{/*  */}"
  end

  it "not crashed work when with binary files (png)" do
    file = fixture("1.png")
    HtmlUnicoder.new(file).encoding.should eq(nil)
    md5(HtmlUnicoder.new(file).to_s).should eq md5(file)
  end

  it "not crashed work when with binary files (zip)" do
    file = fixture("1.png.gz")
    HtmlUnicoder.new(file).encoding.should eq(nil)
    md5(HtmlUnicoder.new(file).to_s).should eq md5(file)
  end

  context "IO" do
    it "finds the right encoding in some arbitrary html" do
      page = fixture_io("bad_encoding2.html")
      page = HtmlUnicoder.new(page).to_s
      page.bytesize.should eq 99258
      page.includes?("Груздовский карьер").should eq true
    end

    it "not crashed work when with binary files (png)" do
      file = fixture_io("1.png")
      HtmlUnicoder.new(file).encoding.should eq(nil)
      md5(HtmlUnicoder.new(file).to_s).should eq md5(fixture("1.png"))
    end

    it "not crashed work when with binary files (zip)" do
      file = fixture_io("1.png.gz")
      HtmlUnicoder.new(file).encoding.should eq(nil)
      md5(HtmlUnicoder.new(file).to_s).should eq md5(fixture("1.png.gz"))
    end

    it "bug?" do
      HtmlUnicoder.new(fixture_io("bug.html")).encoding.should eq({"WINDOWS-1252", :meta})
    end
  end
end
