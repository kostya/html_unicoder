require "./src/html_unicoder"

def fixture(name)
  File.read("#{__DIR__}/spec/fixtures/#{name}")
end

page = fixture("bad_encoding2.html")

t = Time.now
s = 0_u64

10.times do
  u = HtmlUnicoder.new(page)
  page = u.to_s
  s += page.bytesize
end

p s
p Time.now - t
