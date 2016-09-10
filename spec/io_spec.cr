require "./spec_helper"

describe HtmlUnicoder do
  [0, 1, 10, 100, 1000, 1500, 2000, 3500, 4000, 10000].each do |header_size|
    [0, 1000, 10000, 100000, 1_000_000].each do |body_size|
      context "{#{header_size}, #{body_size}}" do
        context "IO" do
          it "no encoding" do
            tag = "<meta charset=utf8>"
            str = "a" * header_size + tag + "b" * body_size
            io = MemoryIO.new(str)
            u = HtmlUnicoder.new(io)
            if header_size > HtmlUnicoder::BUFFER_SIZE + tag.size
              u.encoding.should eq({"UTF-8", :default})
            else
              u.encoding.should eq({"UTF8", :meta})
            end
            page = u.to_s
            page.bytesize.should eq header_size + body_size + 19
            page.should eq str
          end

          it "from cp1251" do
            tag = "<meta charset=cp-1251>" + str(UInt8[242, 229, 234, 241, 242])
            str = "a" * header_size + tag + "b" * body_size
            io = MemoryIO.new(str)
            u = HtmlUnicoder.new(io)
            page = u.to_s
            if header_size > HtmlUnicoder::BUFFER_SIZE + tag.size
              u.encoding.should eq({"UTF-8", :default})
              page.bytesize.should eq header_size + body_size + 22
              page.includes?("текст").should eq false
            else
              u.encoding.should eq({"CP1251", :meta})
              page.bytesize.should eq header_size + body_size + 32
              page.includes?("текст").should eq true
            end
          end

          it "without_buffered, from cp1251" do
            tag = "<meta charset=cp-1251>" + str(UInt8[242, 229, 234, 241, 242])
            str = "a" * header_size + tag + "b" * body_size
            io = SimpleMemoryIO.new(str)
            u = HtmlUnicoder.new(io)
            page = u.to_s
            if header_size > HtmlUnicoder::BUFFER_SIZE + tag.size
              u.encoding.should eq({"UTF-8", :default})
              page.bytesize.should eq header_size + body_size + 22
              page.includes?("текст").should eq false
            else
              u.encoding.should eq({"CP1251", :meta})
              page.bytesize.should eq header_size + body_size + 32
              page.includes?("текст").should eq true
            end
          end
        end

        context "String" do
          it "no encoding" do
            tag = "<meta charset=utf8>"
            str = "a" * header_size + tag + "b" * body_size
            u = HtmlUnicoder.new(str)
            u.encoding.should eq({"UTF8", :meta})
            page = u.to_s
            page.bytesize.should eq header_size + body_size + 19
            page.should eq str
          end

          it "from cp1251" do
            tag = "<meta charset=cp-1251>" + str(UInt8[242, 229, 234, 241, 242])
            str = "a" * header_size + tag + "b" * body_size
            u = HtmlUnicoder.new(str)
            page = u.to_s
            u.encoding.should eq({"CP1251", :meta})
            page.bytesize.should eq header_size + body_size + 32
            page.includes?("текст").should eq true
          end

          it "without_buffered, from cp1251" do
            tag = "<meta charset=cp-1251>" + str(UInt8[242, 229, 234, 241, 242])
            str = "a" * header_size + tag + "b" * body_size
            u = HtmlUnicoder.new(str)
            page = u.to_s
            u.encoding.should eq({"CP1251", :meta})
            page.bytesize.should eq header_size + body_size + 32
            page.includes?("текст").should eq true
          end
        end
      end
    end
  end
end
