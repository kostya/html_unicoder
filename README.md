# html_unicoder

Convert html page to utf-8 for Crystal language.

## Features
* Encoding name parsed from http headers
* Encoding name parsed from page meta tag
* Encoding name normalized to be used in internal Crystal decoder.
* Correctly handle many edge cases
* Convert page as IO to IO
* Result page should be safe utf-8 to use in Crystal

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  html_unicoder:
    github: kostya/html_unicoder
```


## Usage


```crystal
require "html_unicoder"

# basic usage, encoding only from meta tag, or use UTF-8//ignore, by default
page = HtmlUnicoder.new(page, default_encoding: "UTF-8").to_s

# use headers Array(String)
page = HtmlUnicoder.new(page, headers: ["Content-type: text/html; charset=Windows-1251"]).to_s

# use custom encoding
page = HtmlUnicoder.new(page, encoding: "CP1251").to_s

# set use default encoding
HtmlUnicoder.default_encoding = "CP1251"
page = HtmlUnicoder.new(page).to_s

# with http client
require "http/client"
page = ""
HTTP::Client.get("http://www.example.com") do |response|
  page = HtmlUnicoder.new(response.body_io, response.headers).to_s
end

# io -> io
io = HtmlUnicoder.new(io).io
```
