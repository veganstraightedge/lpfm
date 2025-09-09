# LPFM Implementation TODO

This document outlines the development roadmap for the Literate Programming Flavored Markdown (LPFM) Ruby gem.

## Phase 0: Ruby Patterns to Implement

### ✅ Completed

- [x] Simple classes with methods
- [x] Private methods (`## private` + `### method_name`)
- [x] Protected methods (`## protected` + `### method_name`)
- [x] Class methods (`## self.method_name`)
- [x] Method arguments (`## method(args)`)
- [x] Initialize methods
- [x] Inferred class names from filename
- [x] Modules (YAML frontmatter, header prefix, inferred)
- [x] Require statements (YAML frontmatter)
- [x] Include statements (YAML frontmatter)
- [x] Constants (YAML frontmatter and inline)
- [x] Class inheritance (YAML frontmatter and header syntax)
- [x] Methods with default parameters
- [x] attr_reader/attr_writer/attr_accessor (inline and YAML frontmatter)
- [x] Nested attr: reader/writer/accessor (YAML frontmatter)
- [x] Extend statements
- [x] Multiple classes in one file
- [x] Methods with keyword arguments
- [x] Namespaced classes (Namespace::ClassName)
- [x] Empty methods
- [x] Methods with splat arguments (*args, **kwargs)
- [x] Singleton methods
- [x] Methods with blocks (&block)
- [x] Class variables (@@var)
- [x] Alias/alias_method
- [x] method_missing and meta-programming
- [x] Mixed public/private/protected methods

### 🚧 Remaining Patterns

**Advanced Ruby Features:**

- [ ] Nested classes/modules

---

## Phase 1: Core Foundation (MVP)

### 1.1 Internal Data Structure
- [x] Design and implement the core `LPFM` class
- [x] Create internal data structure to represent:
  - [x] Classes and modules with metadata
  - [x] Methods with visibility, arguments, and body
  - [x] Constants and class variables
  - [x] Requires, includes, extends
  - [x] YAML frontmatter metadata
- [x] Implement `#load` method for deferred loading
- [x] Add basic validation and error handling

### 1.2 LPFM Parser (Primary)
- [x] Implement `LPFM::Parser::LPFM` class
- [x] Parse Markdown headings into Ruby structure:
  - [x] H1 (`#`) → classes/modules
  - [x] H2 (`##`) → methods or visibility modifiers
  - [x] H3 (`###`) → methods within visibility scope
- [x] Parse YAML frontmatter for metadata:
  - [x] `attr_reader`, `attr_writer`, `attr_accessor`
  - [x] `require`, `include`, `extend`
  - [x] `constants`
  - [x] `type: module`
  - [x] `inherits_from`
- [x] Handle plain text as method bodies
- [x] Support filename-based class/module inference
- [x] Handle multiple classes/modules in one file

### 1.3 Ruby Converter (Primary)
- [x] Implement `LPFM::Converter::Ruby` class
- [x] Generate proper Ruby syntax from internal structure:
  - [x] Class and module definitions
  - [x] Method definitions with proper arguments
  - [x] Visibility modifiers placement
  - [x] Constants and class variables
  - [x] Require statements at top
  - [x] Include/extend statements
  - [x] Proper indentation and formatting
- [x] Implement `#to_ruby` method on LPFM class
- [x] Add option to include prose as comments

### 1.4 Basic Testing
- [x] Set up RSpec test framework
- [x] Write tests for all 40+ examples in `doc/examples/`
- [x] Test roundtrip: LPFM → Ruby → LPFM consistency
- [x] Edge case testing (empty classes, complex inheritance, etc.)

**Status: Phase 1 Complete! 🎉**
- Core LPFM parsing and Ruby generation working
- 59/59 examples passing (100% success rate)
- All major Ruby constructs supported
- Comprehensive test coverage

## Phase 2: Extended Parsers and Converters

### 2.0 Additional Converters
- [x] Implement `LPFM::Converter::Markdown` class
- [x] Add `#to_markdown` and `#to_md` methods
- [x] Generate Markdown with fenced Ruby code blocks

### 2.1 Ruby Parser (Reverse Engineering)
- [x] Integrate Prism gem for Ruby AST parsing
- [x] Implement `LPFM::Parser::Ruby` class
- [x] Convert Ruby AST to LPFM internal structure:
  - [x] Classes/modules → H1 headings
  - [x] Methods → H2/H3 headings
  - [x] Comments → Markdown prose
  - [x] Extract metadata for YAML frontmatter
- [x] Handle complex Ruby constructs
- [x] Support `type: :ruby` in constructor

**Status: Phase 2.1 Complete! 🎉**
- Full Ruby AST parsing using built-in Prism gem
- Comprehensive Ruby construct support:
  - Class and module definitions with inheritance
  - Method definitions with all argument types (required, optional, splat, keyword, block)
  - Visibility modifiers (public, private, protected)
  - attr_reader/attr_writer/attr_accessor declarations
  - Constants and class variables
  - require, include, extend statements
  - alias_method declarations
- Roundtrip conversion: Ruby → LPFM → Ruby maintains semantic consistency
- 16 comprehensive test cases covering all major Ruby features
- Error handling for invalid Ruby syntax

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

## Principles

- Don’t use "Base" as a class name unless your domain is a fort, a sport, or the chemical sort.
