# frozen_string_literal: true

module LPFM
  module Parser
    # Foundation class for all LPFM parsers
    class Foundation
      attr_reader :content, :lpfm_object

      def initialize(content, lpfm_object)
        @content = content
        @lpfm_object = lpfm_object
      end

      def parse
        raise NotImplementedError, "Subclasses must implement #parse method"
      end

      protected

      def extract_yaml_frontmatter
        return [nil, @content] unless @content.start_with?('---')

        parts = @content.split(/^---\s*$/, 3)
        if parts.length >= 3
          yaml_content = parts[1].strip
          remaining_content = parts[2].strip
          begin
            require 'yaml'
            metadata = YAML.safe_load(yaml_content) || {}
            [metadata, remaining_content]
          rescue => e
            raise Error, "Invalid YAML frontmatter: #{e.message}"
          end
        else
          [nil, @content]
        end
      end

      def normalize_whitespace(text)
        return "" if text.nil?

        text.strip.gsub("\r\n", "\n")
      end

      def split_into_lines(text)
        normalize_whitespace(text).split("\n")
      end

      def extract_heading_info(line)
        return nil unless line.start_with?('#')

        match = line.match(/^(#+)\s*(.*)/)
        return nil unless match

        level = match[1].length
        title = match[2].strip

        { level: level, title: title, raw: line }
      end

      def is_heading?(line)
        line.strip.start_with?('#')
      end

      def is_empty_line?(line)
        line.strip.empty?
      end

      def clean_method_name(name)
        # Handle method names with arguments
        method_name = name.split('(').first.strip
        # Handle class methods (self.method_name)
        method_name.sub(/^self\./, '')
      end

      def extract_method_arguments(name)
        if name.include?('(') && name.include?(')')
          args_part = name[(name.index('(') + 1)...name.rindex(')')]
          args_part.split(',').map(&:strip).reject(&:empty?)
        else
          []
        end
      end

      def is_class_method?(name)
        name.start_with?('self.') || name.include?('self.') || is_object_singleton_method?(name)
      end

      def is_object_singleton_method?(name)
        # Check if it's an object singleton method like admin.method_name or user.method_name
        # But not self.method_name which is handled separately
        # Extract just the method name part (before any parentheses) to avoid false positives from parameter values
        method_name_part = name.split('(').first.strip
        method_name_part.include?('.') && !method_name_part.include?('self.')
      end

      def is_visibility_modifier?(name)
        %w[private protected public].include?(name.strip.downcase)
      end
    end
  end
end
