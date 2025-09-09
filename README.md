# Literate Programming Flavored Markdown (LPFM)

_Literate Programming Flavored Markdown (LPFM)_ is a file format, syntax, and data structure for _literate programming_.
It combines prose and code in the same file.

In an `.lpfm` file…
**Prose** for humans is written in _Markdown_.
**Code** for machines is also written in _Markdown_!

_LPFM_ is a flavor of _Markdown_, similar to how _GitHub Flavored Markdown_ is a flavor of _Markdown_.
_LPFM_ is inspired by Markdown, similar to how _Fountain_ and _Highland_ are inspired by _Markdown_.

https://lpfm-lang.org
https://github.com/veganstraightedge/lpfm

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add lpfm
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install lpfm
```

---

## Naming

Acceptable abbreviations of _Literate Programming Flavored Markdown_ are:

- LitProgFM in prose
- _LPFM_ for prose shorthand, in implementation `class`/`module` names, etc
- `lpfm` for CLI tool name and file extension

## File extensions

Acceptable file extensions for _Literate Programming Flavored Markdown_ files are:

- `.lpfm` **preferred**
- `.lpfm.md`
- `.lpfm.markdown`
- `.lp.markdown`
- `.lp.md`

## Examples

A simple example where would turn this `LPFM`:

`dog.lpfm`

```md
# Dog
## speak
puts "woof!"

```

into this Ruby code `dog.rb`

```ruby
class Dog
  def speak
    puts "woof!"
  end
end
```


More examples can be found in the `/doc/examples` folder.

## Components

Internal implementation is made up of three main domains:

- `Loader`
- `Parsers`
- `Converters`

**`Loader`** is responsible for reading input files for `Parser`.

**`Parsers`** are responsible for turning the input into a robust internal data structure.
One parser for each type of input.

**`Converters`** are responsible for turning the robust internal data structure into output.
One converter for each type of output.

### Loader

Behind the scenes, mostly never used by end user directly.
Mostly only used by `Parser`.

#### Usage

If `LPFM.new()` is given no argument, then an empty `LPFM` object is created.
Before it can be converted to any other format, content must be loaded with `#load`.

```ruby
lpsm = LPFM.new
lpsm.load file_or_string
```

This two step approach is equivalent to:

```ruby
LPFM.new file_or_string
```

### Parser

_LPFM_ uses Markdown information hierarchy to create valid Ruby code.

  - H1 `#` defines a class or module
  - H2 `##` defines a method
  - H2 `##` also switches to `private`/`protected`/`public` method definitions
  - H3 `###` following a H2 of `private`/`protected`/`public` are method definitions in that scope
  - Plain text after a method definition heading is the method body
  - Plain text before an H1 is Ruby code outside of a method definition (CONSTANTS, etc)
  - YAML frontmatter is also used for meta data (`attr_*`, type: `module`, `require`, `include`, `constants`, class inheritance with `inherits_from`, etc)

Instead of wrapping all code in fencing like "```ruby",
_LPFM_ has some sort of syntax to toggle between code mode and prose mode.
For example, an empty heading or heading with only hyphens and/or octothorps:

```markdown
#
# # # # #
# --- #
# ---
```

_LPFM_ content is parsed into an internal `LPFM` data structure object.

#### Usage

```ruby
LPFM.new file_or_string = nil, type: :lpfm
```

The input arg for `LPFM.new` can be either a `String` or a `File`.

`LPFM.new` auto-detects if `file_or_string` is a `File` or `String`.
If it's a `File`, it first reads it into memory as a `String`, then everything else is the same.

Allowed values for `type:` are:

- `:ruby`
- `:markdown`
- `:ast`

#### From LPFM

Parse input into an `LPFM` object.

Input argument `file_or_string` is a `String` of _LPFM_ content or a `File` with _LPFM_ content in it.

```ruby
LPFM.new(file_or_string, type: :lpfm)
```

The default `type` is `:lpfm`, so you may omit it if you want when loading _LPFM_ content.

```ruby
LPFM.new file_or_string
```

#### From Ruby

Parse input into an `LPFM` object.

Input argument `file_or_string` is a `String` of _Ruby_ or a `.rb` `File` with _Ruby_ content in it.

Input argument `type` tells the parser to expect and treat it as `Ruby` content.
Parse it using the _Prism_ gem, into an `LPFM` object.

Turn Ruby `class`/`module`/`method` definitions in to Markdown headings.
Turn Ruby comments into Markdown prose.

```ruby
LPFM.new file_or_string, type: :ruby
```

#### From Markdown

Parse input into an `LPFM` object.

Input argument `file_or_string` is a `String` of _Markdown_ or a `.md`/`.markdown` `File` with _Markdown_ content in it.

Input argument `type` tells the parser to expect and treat it as `Markdown` content.
Parse it using the _Kramdown_ gem, into an `LPFM` object.

Turn fenced code definitions into _LPFM_.
Turn Markdown prose into Markdown prose inside of _LPFM_ mode toggles.

```ruby
LPFM.new file_or_string, type: :ruby
```

#### From Ruby AST (Prism)

Parse input into an `LPFM` object.

Input argument `file_or_string` is a `String` of a _Ruby AST_ or a `File` with _Ruby AST_ content in it.

Input argument `type` tells the parser to expect and treat it as `AST` content, compatible with _Prism_'s `AST`.
Parse it using the a gem (TBD), into an `LPFM` object.

Turn code definitions into _LPFM_.
Turn Markdown prose into Markdown prose inside of _LPFM_ mode toggles.

```ruby
LPFM.new file_or_string, type: :ruby_ast
```

---

### Converters

An _LPFM_ object can be converted to and outputted as different formats using conventionally named `to_*` Ruby methods:

- `to_s` - pretty printed `String`
- `to_h` - big Ruby `Hash`
- `to_json` - `to_h`, then Ruby's `Hash#to_json`
- `to_yaml` - `to_h`, then Ruby's `Hash#to_yaml`
- `to_ast` - using some AST builder library/Rubygem
- `to_markdown` - Markdown file with ``` fenced code blocks
- `to_md` - alias of `to_markdown`
- `to_ruby` - Ruby file, optionally with the prose as comments
- `to_lpfm` - LPFM file, combining prose and code

Maybe there should be a `.to(type)` method as well?
In that case, these two lines would be equivalent:

```ruby
LPFM.new(file_or_string, type: :lpfm).to(:markdown)
LPFM.new(file_or_string, type: :lpfm).to_markdown
```

Each would call upon the `Converter` for that type of output, `Converter::Markdown` (or similar) in this case.

#### Usage

Assuming we have already initialized a new `LPFM` object from a source:

```ruby
lpfm = LPFM.new file_or_string
```

We can then convert to other formats:

```ruby
lpfm.to_s
lpfm.to_h
lpfm.to_json
lpfm.to_yaml
lpfm.to_ast
lpfm.to_markdown
lpfm.to_md
lpfm.to_ruby
lpfm.to_lpfm
```

### Future vision

For now, _LPFM_ is built as a Rubygem with `Ruby` code blocks.
The reason is because I (Shane Becker, the creator of _LPFM_) am primarily a Rubyist.
But!
I imagine a future where _LPFM_ as a content format is agnostic to which language/s the code is written in.
It could be `Python`, `Javascript`, `Swift`, …whatever!

Examples:

```ruby
lpfm = LPFM.new file_or_string, type: :python
lpfm.to_markdown
```

```ruby
lpfm = LPFM.new file_or_string, type: :swift
lpfm.to_lpfm
```

We don't need to build any of that at first, but whatever we build for Ruby at first, it should be built with that polyglot future in mind.

_Markdown_ is the only language for prose and file structure though.

#### Command line interface (CLI)

A Rubygem is not enough.
There needs to be a CLI, as well.
So it can be used by non-Rubyists, outside of Ruby environments, in CI/CD flow, in build tools, etc.

The interface would be something like:

```sh
lpfm path/to/input_file.lpfm path/to/output_file.rb
```

## References

- Literate programming: https://en.wikipedia.org/wiki/Literate_programming
- Markdown: https://daringfireball.net/projects/markdown
- Ruby: https://www.ruby-lang.org/en
- Kramdown: https://kramdown.gettalong.org
- Prism: https://github.com/ruby/prism
- Rubocop: https://rubocop.org
- CommonMark: https://commonmark.org
- Fountain: https://fountain.io
- Highland: https://quoteunquoteapps.com/highland-pro

---

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/veganstraightedge/lpfm. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/veganstraightedge/lpfm/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lpfm project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/veganstraightedge/lpfm/blob/main/CODE_OF_CONDUCT.md).
