# html_unicoder

Convert incoming html page to unicode for Crystal language. Encoding correctly parsed from http headers or meta tag. Correctly handle many edge cases, so result page should be safe utf-8 to use in Crystal.

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

# basic usage, encoding fetched only from meta tag, or use UTF-8//ignore, by default
page = HtmlUnicoder.new(page).to_s

# use headers Array(String)
page = HtmlUnicoder.new(page, headers: ["Content-type: text/html; charset=Windows-1251"]).to_s

# use custom encoding
page = HtmlUnicoder.new(page, encoding: "CP1251").to_s

# use custom encoding
page = HtmlUnicoder.new(page, encoding: "CP1251").to_s

```
