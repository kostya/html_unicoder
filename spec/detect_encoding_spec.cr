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
      HtmlUnicoder.new(page).encoding.should eq({"WINDOWS-1251", :meta})

      page = %{<head><meta charset="utf8"></head>текст}
      HtmlUnicoder.new(page).encoding.should eq({"UTF8", :meta})

      page = %{<head><meta charset=koi8r></head>текст}
      HtmlUnicoder.new(page).encoding.should eq({"KOI8-R", :meta})
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

    it "big content" do
      page = <<-HTML
      <HTML>
      <HEAD>
      <TITLE>แฟรนไชส์ไปรษณีย์,แฟรนไชส์,แฟรนไชส์ร้านถ่ายเอกสาร,เปิดร้านถ่ายเอกสาร,เปิดร้านถ่ายรูป,แฟรนไชส์จุดรับชำระ,ธุรกิจน่าลงทุน,แฟรนไชส์น่าลงทุน,เปิดร้านอะไรดี,ร้านสารพัดบริการ,ไปรษณีย์เอกชน,เคาน์เตอร์เซอร์วิส</TITLE>
      <meta name="keywords" content="แฟรนไชส์,ไปรษณีย์,ไปรษณีย์เอกชน,แฟรนไชส์ไปรษณีย์,แฟรนไชส์ไปรษณีย์เอกชน,แฟรนไชส์ร้านสารพัดบริการ,ร้านสารพัดบริการชุมชนครบวงจร,พรบ.,ประกันภัย,ร้านสะดวกซื้อบริการ,ร้านสะดวกซื้อด้านบริการ,อาชีพอิสระ,Franchise,Sme,ธุรกิจส่วนตัว,ธุรกิจบริการ,SMEs,เติมเงินออนไลน์,ต่อทะเบียนรถ,เสียภาษีรถ,ภาษีรถยนต์,แฟรนไชส์ พ.ร.บ.,One stop service,แฟรนไชส์จุดรับชำระค่าบริการ,จุดรับชำระค่าบริการ,ชำระเงินออนไลน์,จุดรับชำระเงิน,ชำระค่าสาธารณูปโภค,ประกันภัยรถยนต์,ถ่ายเอกสาร,เคลือบบัตร,ศูนย์ถ่ายเอกสาร,ศูนย์ถ่ายรูปด่วน,ร้านถ่ายรูปด่วน,เปิดร้าน,จองตั๋วเดินทาง,จองตั๋วรถทัวร์,จองตั๋วเครื่องบิน,จุดจองตั๋วเดินทาง,บริการโอนเงินด่วน,บริการงานธนาคาร,บริการส่งพัสดุ,เติมเงินมือถือ,บริการส่งแฟ็กซ์,ธนาณัติ,แฟรนไชส์ไทย,ธุรกิจแฟรนไชส์,ธุรกิจไปรษณีย์,แฟรนไชส์เคาเตอร์เซอร์วิส,เคาเตอเซอร์วิส,เคาเตอร์เซอร์วิส,แฟรนไชส์ประกันรถยนต์,ต่อภาษีออนไลน์,แฟรนไชส์จองตั๋ว">
      <meta name="keywords" content=
      "แฟรนไชส์,ไปรษณีย์,ไปรษณีย์เอกชน,แฟรนไชส์ไปรษณีย์,แฟรนไชส์ไปรษณีย์เอกชน,แฟรนไชส์ร้านสารพัดบริการ,ร้านสารพัดบริการชุมชนครบวงจร,พรบ.,ประกันภัย,ร้านสะดวกซื้อบริการ,ร้านสะดวกซื้อด้านบริการ,อาชีพอิสระ,Franchise,Sme,ธุรกิจส่วนตัว,ธุรกิจบริการ,SMEs,เติมเงินออนไลน์,ต่อทะเบียนรถ,เสียภาษีรถ,ภาษีรถยนต์,แฟรนไชส์ พ.ร.บ.,One stop service,แฟรนไชส์จุดรับชำระค่าบริการ,จุดรับชำระค่าบริการ,ชำระเงินออนไลน์,จุดรับชำระเงิน,ชำระค่าสาธารณูปโภค,ประกันภัยรถยนต์,ถ่ายเอกสาร,เคลือบบัตร,ศูนย์ถ่ายเอกสาร,ศูนย์ถ่ายรูปด่วน,ร้านถ่ายรูปด่วน,เปิดร้าน,จองตั๋วเดินทาง,จองตั๋วรถทัวร์,จองตั๋วเครื่องบิน,จุดจองตั๋วเดินทาง,บริการโอนเงินด่วน,บริการงานธนาคาร,บริการส่งพัสดุ,เติมเงินมือถือ,บริการส่งแฟ็กซ์,ธนาณัติ,แฟรนไชส์ไทย,ธุรกิจแฟรนไชส์,ธุรกิจไปรษณีย์,แฟรนไชส์เคาเตอร์เซอร์วิส,เคาเตอเซอร์วิส,เคาเตอร์เซอร์วิส,แฟรนไชส์ประกันรถยนต์,ต่อภาษีออนไลน์,แฟรนไชส์จองตั๋ว">
      <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=tis-620">
      HTML
      HtmlUnicoder.new(page).encoding.should eq({"TIS-620", :meta})
    end

    context "default_encoding" do
      it "when even not set default, is UTF-8" do
        HtmlUnicoder.new("текст").encoding.should eq(nil)
      end

      it "set default" do
        HtmlUnicoder.default_encoding = "CP1251"
        HtmlUnicoder.new("текст").encoding.should eq({"CP1251", :default})
      end

      it "set default incorrectly" do
        HtmlUnicoder.default_encoding = "asdfadsf"
        HtmlUnicoder.new("текст").encoding.should eq(nil)
      end
    end

    context "#default_encoding" do
      it "set ok" do
        HtmlUnicoder.new("", default_encoding: "CP1251").encoding.should eq({"CP1251", :default})
      end

      it "set is before class default" do
        HtmlUnicoder.default_encoding = "CP1251"
        HtmlUnicoder.new("", default_encoding: "CP1254").encoding.should eq({"CP1254", :default})
      end

      it "set default incorrectly" do
        HtmlUnicoder.default_encoding = "CP1251"
        HtmlUnicoder.new("", default_encoding: "asdfsdf").encoding.should eq({"CP1251", :default})
      end
    end
  end
end
