# frozen_string_literal: true

require_relative "lpfm/version"
require_relative "lpfm/data/class_definition"
require_relative "lpfm/data/module_definition"
require_relative "lpfm/data/method_definition"

module LPFM
  class Error < StandardError; end

  # Core LPFM class for literate programming with Markdown
  class LPFM
    attr_reader :content, :type, :classes, :modules, :requires, :metadata

    def initialize(file_or_string = nil, type: :lpfm)
      @type = type
      @content = nil
      @classes = {}
      @modules = {}
      @requires = []
      @metadata = {}

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
    rescue => e
      raise Error, "Failed to load content: #{e.message}"
    end

    private

    def load_from_string(string)
      # Check if string is a file path
      if string.include?("\n") || string.include?("#") || string.include?("---")
        # Looks like content, not a file path
        string
      elsif File.exist?(string)
        # It's a file path that exists
        File.read(string)
      else
        # Treat as raw content
        string
      end
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
      # Basic LPFM validation - should have at least one heading
      unless @content.match?(/^#[^#]/)
        raise Error, "LPFM content must contain at least one H1 heading"
      end
    end

    def validate_ruby_content
      # Basic Ruby syntax check would go here
      # For now, just check it's not empty
      true
    end

    def validate_markdown_content
      # Basic Markdown validation would go here
      # For now, just check it's not empty
      true
    end

    def parse_content
      # TODO: Implement parsing logic based on @type
      # For now, just store the content
    end

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

    def has_classes?
      !@classes.empty?
    end

    def has_modules?
      !@modules.empty?
    end

    def has_requires?
      !@requires.empty?
    end
  end
end
