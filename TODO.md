# LPFM Implementation TODO

This document outlines the development roadmap for the Literate Programming Flavored Markdown (LPFM) Ruby gem.

## Phase 1: Core Foundation (MVP)

### 1.1 Internal Data Structure
- [ ] Design and implement the core `LPFM` class
- [ ] Create internal data structure to represent:
  - [ ] Classes and modules with metadata
  - [ ] Methods with visibility, arguments, and body
  - [ ] Constants and class variables
  - [ ] Requires, includes, extends
  - [ ] YAML frontmatter metadata
- [ ] Implement `#load` method for deferred loading
- [ ] Add basic validation and error handling

### 1.2 LPFM Parser (Primary)
- [ ] Implement `LPFM::Parser::LPFM` class
- [ ] Parse Markdown headings into Ruby structure:
  - [ ] H1 (`#`) → classes/modules
  - [ ] H2 (`##`) → methods or visibility modifiers
  - [ ] H3 (`###`) → methods within visibility scope
- [ ] Parse YAML frontmatter for metadata:
  - [ ] `attr_reader`, `attr_writer`, `attr_accessor`
  - [ ] `require`, `include`, `extend`
  - [ ] `constants`
  - [ ] `type: module`
  - [ ] `inherits_from`
- [ ] Handle plain text as method bodies
- [ ] Support filename-based class/module inference
- [ ] Handle multiple classes/modules in one file

### 1.3 Ruby Converter (Primary)
- [ ] Implement `LPFM::Converter::Ruby` class
- [ ] Generate proper Ruby syntax from internal structure:
  - [ ] Class and module definitions
  - [ ] Method definitions with proper arguments
  - [ ] Visibility modifiers placement
  - [ ] Constants and class variables
  - [ ] Require statements at top
  - [ ] Include/extend statements
  - [ ] Proper indentation and formatting
- [ ] Implement `#to_ruby` method on LPFM class
- [ ] Add option to include prose as comments

### 1.4 Basic Testing
- [ ] Set up RSpec test framework
- [ ] Write tests for all 40+ examples in `doc/examples/`
- [ ] Test roundtrip: LPFM → Ruby → LPFM consistency
- [ ] Edge case testing (empty classes, complex inheritance, etc.)

## Phase 2: Extended Parsers and Converters

### 2.0 Additional Converters
- [ ] Implement `LPFM::Converter::Markdown` class
- [ ] Add `#to_markdown` and `#to_md` methods
- [ ] Generate Markdown with fenced Ruby code blocks

### 2.1 Ruby Parser (Reverse Engineering)
- [ ] Integrate Prism gem for Ruby AST parsing
- [ ] Implement `LPFM::Parser::Ruby` class
- [ ] Convert Ruby AST to LPFM internal structure:
  - [ ] Classes/modules → H1 headings
  - [ ] Methods → H2/H3 headings
  - [ ] Comments → Markdown prose
  - [ ] Extract metadata for YAML frontmatter
- [ ] Handle complex Ruby constructs
- [ ] Support `type: :ruby` in constructor

### 2.2 Markdown Parser
- [ ] Integrate Kramdown gem for Markdown parsing
- [ ] Implement `LPFM::Parser::Markdown` class
- [ ] Convert fenced code blocks to LPFM structure
- [ ] Preserve non-code Markdown as prose
- [ ] Support `type: :markdown` in constructor

### 2.3 Additional Converters
- [ ] Implement `#to_lpfm` for roundtrip conversion
- [ ] Add `#to_s` for pretty-printed output

### 2.4 Data Export Converters
- [ ] Implement `#to_h` for Hash representation
- [ ] Implement `#to_json` using `#to_h`
- [ ] Implement `#to_yaml` using `#to_h`
- [ ] Consider `#to_ast` for AST export
- [ ] Add generic `#to(type)` method

## Phase 3: CLI Tool

### 3.1 Command Line Interface
- [ ] Create `bin/lpfm` executable
- [ ] Implement argument parsing for input/output files
- [ ] Support format detection from file extensions
- [ ] Add help and usage information
- [ ] Handle errors gracefully with user-friendly messages

### 3.2 CLI Features
- [ ] Support multiple input formats: `.lpfm`, `.rb`, `.md`
- [ ] Support multiple output formats: `.lpfm`, `.rb`, `.md`
- [ ] Add verbose/quiet modes
- [ ] Add validation mode (syntax checking)
- [ ] Support batch processing of multiple files

## Phase 4: Advanced Features

### 4.1 Enhanced Parsing
- [ ] Support prose/code mode toggling with empty headings
- [ ] Handle complex method signatures (blocks, lambdas)
- [ ] Support nested classes and modules
- [ ] Add macro support for common patterns
- [ ] Improve error messages with line numbers

### 4.2 Code Quality Integration
- [ ] Integrate with RuboCop for style checking
- [ ] Add auto-formatting of generated Ruby code
- [ ] Support custom Ruby style configurations
- [ ] Add linting for LPFM syntax

### 4.3 Documentation Features
- [ ] Generate rich HTML documentation
- [ ] Support cross-references between methods/classes
- [ ] Add table of contents generation
- [ ] Support diagrams and flowcharts in prose

## Phase 5: Future Vision (Polyglot)

### 5.1 Language Abstraction
- [ ] Refactor core to be language-agnostic
- [ ] Create plugin architecture for different languages
- [ ] Define common interface for language parsers/converters

### 5.2 Additional Language Support
- [ ] Python support (`type: :python`)
- [ ] JavaScript support (`type: :javascript`)
- [ ] Swift support (`type: :swift`)
- [ ] Generic language framework

## Development Guidelines

### Code Quality
- [ ] Maintain 100% test coverage
- [ ] Follow Ruby style guide and use RuboCop
- [ ] Write comprehensive documentation
- [ ] Use semantic versioning
- [ ] Add type signatures with RBS

### Performance
- [ ] Profile parsing performance with large files
- [ ] Optimize memory usage for batch processing
- [ ] Add streaming support for very large files
- [ ] Consider caching for repeated conversions

### Documentation
- [ ] Update README with examples and API docs
- [ ] Create comprehensive user guide
- [ ] Add architecture documentation
- [ ] Write contributor guide

### CI/CD
- [ ] Set up GitHub Actions for automated testing
- [ ] Add automated gem publishing
- [ ] Test across multiple Ruby versions
- [ ] Add integration tests with real-world examples

## Implementation Priority

1. **Start with Phase 1**: Get basic LPFM parsing and Ruby generation working
2. **Use examples as tests**: Each example should pass before moving forward
3. **Iterate quickly**: Build MVP first, then add complexity
4. **Commit early, commit often**: Regularly commit changes to track progress
5. **Focus on core use case**: LPFM → Ruby conversion is the primary goal
6. **Design for extensibility**: Keep future polyglot vision in mind

## Success Metrics

- [ ] All 40+ examples in `doc/examples/` convert correctly
- [ ] Roundtrip conversion maintains semantic equivalence
- [ ] CLI tool handles real-world Ruby projects
- [ ] Performance suitable for CI/CD integration
- [ ] Documentation enables community adoption

## Notes

- Keep the internal data structure flexible for future language support
- Define a pattern for converters and parsers to follow and inherit from
- Plan for streaming/incremental parsing of large files
- Design error handling to be helpful for debugging LPFM syntax
- Consider integration with existing Ruby toolchain (Bundler, RubyGems, etc.)
