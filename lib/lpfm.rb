# frozen_string_literal: true

require_relative "lpfm/version"
require_relative "lpfm/data/class_definition"
require_relative "lpfm/data/module_definition"
require_relative "lpfm/data/method_definition"
require_relative "lpfm/parser/lpfm"
require_relative "lpfm/parser/ruby"
require_relative "lpfm/converter/ruby"
require_relative "lpfm/converter/markdown"

module LPFM
  class Error < StandardError; end

  # Core LPFM class for literate programming with Markdown
  class LPFM
    attr_reader :content, :type, :classes, :modules, :requires, :metadata, :filename

    def initialize(file_or_string = nil, type: :lpfm)
      @type = type
      @content = nil
      @classes = {}
      @modules = {}
      @requires = []
      @metadata = {}
      @filename = nil

      load(file_or_string) if file_or_string
    end

    def load(file_or_string)
      raise ArgumentError, "Cannot load nil content" if file_or_string.nil?

      @content = case file_or_string
                 when String
                   load_from_string(file_or_string)
                 when File
                   load_from_file(file_or_string)
                 else
                   raise ArgumentError, "Expected String or File, got #{file_or_string.class}"
                 end

      validate_content
      parse_content
      self
    rescue ArgumentError => e
      raise e
    rescue StandardError => e
      raise Error, "Failed to load content: #{e.message}"
    end

    private

    def load_from_string(string)
      # Check if string is a file path
      if string.include?("\n") || string.include?("#") || string.include?("---")
        # Looks like content, not a file path
        # Treat as raw content
        return string
      end

      if File.exist?(string)
        # It's a file path that exists
        @filename = string
        return File.read(string)
      end

      string
    end

    def load_from_file(file)
      raise ArgumentError, "File is not readable" unless file.respond_to?(:read)

      file.read
    end

    def validate_content
      raise Error, "Content cannot be empty" if @content.nil? || @content.strip.empty?

      case @type
      when :lpfm
        validate_lpfm_content
      when :ruby
        validate_ruby_content
      when :markdown
        validate_markdown_content
      end
    end

    def validate_lpfm_content
      # Basic LPFM validation - should have at least one heading OR be suitable for filename inference
      has_h1_heading = @content.match?(/^#[^#]/)
      has_other_headings = @content.match?(/^##/)
      has_yaml_frontmatter = @content.start_with?("---")
      has_content = !@content.strip.empty?

      # Allow filename inference if we have methods (H2) or YAML frontmatter but no H1, AND we have a filename
      can_infer_from_filename = @filename && (has_other_headings || has_yaml_frontmatter) && has_content

      return if has_h1_heading || can_infer_from_filename

      raise Error, "LPFM content must contain at least one H1 heading or be suitable for filename-based inference"
    end

    def validate_ruby_content
      # Use Prism to validate Ruby syntax
      result = Prism.parse(@content)
      if result.failure?
        errors = result.errors.map(&:message).join(", ")
        raise Error, "Invalid Ruby syntax: #{errors}"
      end
      true
    end

    def validate_markdown_content
      # Basic Markdown validation would go here
      # For now, just check it's not empty
      true
    end

    def parse_content
      case @type
      when :lpfm
        parser = Parser::LPFM.new(@content, self, @filename)
        parser.parse
      when :ruby
        parser = Parser::Ruby.new(@content, self, @filename)
        parser.parse
      when :markdown
        # TODO: Implement Markdown parser
        raise Error, "Markdown parsing not yet implemented"
      else
        raise Error, "Unknown content type: #{@type}"
      end
    end

    public

    def add_class(name)
      @classes[name] = Data::ClassDefinition.new(name)
    end

    def add_module(name)
      @modules[name] = Data::ModuleDefinition.new(name)
    end

    def add_require(requirement)
      @requires << requirement unless @requires.include?(requirement)
    end

    def get_class(name)
      @classes[name]
    end

    def get_module(name)
      @modules[name]
    end

    def classes?
      !@classes.empty?
    end

    def modules?
      !@modules.empty?
    end

    def requires?
      !@requires.empty?
    end

    # Convert to Ruby code
    def to_ruby
      Converter::Ruby.new(self).convert
    end

    # Convert to Markdown with fenced Ruby code blocks
    def to_markdown
      Converter::Markdown.new(self).convert
    end
    alias to_md to_markdown
  end
end
