# frozen_string_literal: true

module LPFM
  module Converter
    # Base class for all LPFM converters
    class Base
      attr_reader :lpfm_object

      def initialize(lpfm_object)
        @lpfm_object = lpfm_object
      end

      def convert
        raise NotImplementedError, "Subclasses must implement #convert method"
      end

      protected

      def has_content?
        @lpfm_object.has_classes? || @lpfm_object.has_modules?
      end

      def format_indentation(text, level = 1)
        return "" if text.nil? || text.empty?

        indent = "  " * level
        text.split("\n").map { |line| line.empty? ? line : "#{indent}#{line}" }.join("\n")
      end

      def format_method_arguments(arguments)
        return "" if arguments.empty?
        "(#{arguments.join(', ')})"
      end

      def format_attribute_list(attributes)
        return "" if attributes.empty?
        attributes.map { |attr| ":#{attr}" }.join(", ")
      end

      def normalize_constant_value(value)
        case value
        when String
          # Check if it's already quoted
          if value.start_with?('"') && value.end_with?('"')
            value
          elsif value.start_with?("'") && value.end_with?("'")
            value
          else
            "\"#{value}\""
          end
        when Numeric, TrueClass, FalseClass, NilClass
          value.inspect
        else
          value.to_s
        end
      end

      def format_requires(requires)
        return "" if requires.empty?
        requires.map { |req| "require '#{req}'" }.join("\n") + "\n"
      end

      def extract_prose_sections(object)
        # Extract any prose/documentation from the object
        prose = object.respond_to?(:prose) ? object.prose : {}
        prose.select { |_, text| !text.nil? && !text.strip.empty? }
      end

      def format_prose_as_comments(prose, indent_level = 0)
        return "" if prose.empty?

        indent = "  " * indent_level
        prose.map do |section, text|
          lines = text.split("\n").map { |line| "#{indent}# #{line}".rstrip }
          lines.join("\n")
        end.join("\n") + "\n"
      end
    end
  end
end
