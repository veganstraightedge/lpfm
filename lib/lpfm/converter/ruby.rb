# frozen_string_literal: true

require_relative 'base'

module LPFM
  module Converter
    # Converter for generating Ruby code from LPFM internal structure
    class Ruby < Base
      def convert(include_prose_as_comments: false)
        return "" unless has_content?

        output = []

        # Add requires at the top
        output << format_requires(@lpfm_object.requires)

        # Convert classes
        @lpfm_object.classes.each do |name, class_def|
          output << convert_class(class_def, include_prose_as_comments)
        end

        # Convert modules
        @lpfm_object.modules.each do |name, module_def|
          output << convert_module(module_def, include_prose_as_comments)
        end

        output.reject(&:empty?).join("\n")
      end

      private

      def convert_class(class_def, include_prose = false)
        output = []

        # Add class prose as comments if requested
        if include_prose
          prose_sections = extract_prose_sections(class_def)
          output << format_prose_as_comments(prose_sections) unless prose_sections.empty?
        end

        # Class definition line
        class_line = "class #{class_def.name}"
        class_line += " < #{class_def.inherits_from}" if class_def.inherits_from
        output << class_line

        # Class body
        body_parts = []

        # Add includes first (Ruby convention)
        class_def.includes.each do |include_mod|
          body_parts << "include #{include_mod}"
        end

        # Add extends
        class_def.extends.each do |extend_mod|
          body_parts << "extend #{extend_mod}"
        end

        # Add spacing after includes/extends if we have other content
        if (class_def.has_includes? || class_def.extends.any?) &&
           (class_def.has_attr_methods? || class_def.has_constants? || class_def.has_class_variables? || class_def.has_methods?)
          body_parts << ""
        end

        # Add attr_* methods
        body_parts.concat(format_attr_methods(class_def))

        # Add constants
        class_def.constants.each do |name, value|
          body_parts << "#{name} = #{normalize_constant_value(value)}"
        end

        # Add class variables
        class_def.class_variables.each do |name, value|
          body_parts << "#{name} = #{normalize_constant_value(value)}"
        end

        # Add spacing after constants/class variables if we have methods
        if class_def.has_methods? && (class_def.has_constants? || class_def.has_class_variables? || class_def.has_attr_methods?)
          body_parts << ""
        end

        # Group methods by visibility
        public_methods = class_def.methods.select(&:public?)
        private_methods = class_def.methods.select(&:private?)
        protected_methods = class_def.methods.select(&:protected?)

        # Add public methods
        public_methods.each_with_index do |method, index|
          body_parts << "" if index > 0  # Add blank line between methods
          body_parts << convert_method(method, include_prose)
        end

        # Add private methods
        unless private_methods.empty?
          body_parts << ""
          body_parts << "private"
          body_parts << ""
          private_methods.each_with_index do |method, index|
            body_parts << "" if index > 0  # Add blank line between methods
            body_parts << convert_method(method, include_prose)
          end
        end

        # Add protected methods
        unless protected_methods.empty?
          body_parts << ""
          body_parts << "protected"
          body_parts << ""
          protected_methods.each_with_index do |method, index|
            body_parts << "" if index > 0  # Add blank line between methods
            body_parts << convert_method(method, include_prose)
          end
        end

        # Add aliases at the end
        if class_def.has_aliases?
          body_parts << ""
          class_def.aliases.each do |alias_name, original_method|
            body_parts << "alias #{alias_name} #{original_method}"
          end
          class_def.alias_methods.each do |alias_name, original_method|
            body_parts << "alias_method :#{alias_name}, :#{original_method}"
          end
        end

        # Format class body with proper indentation
        unless body_parts.empty?
          formatted_body = body_parts.map { |part|
            part.empty? ? "" : format_indentation(part)
          }.join("\n")
          output << formatted_body
        end

        output << "end"
        output.join("\n")
      end

      def convert_module(module_def, include_prose = false)
        output = []

        # Add module prose as comments if requested
        if include_prose
          prose_sections = extract_prose_sections(module_def)
          output << format_prose_as_comments(prose_sections) unless prose_sections.empty?
        end

        # Module definition line
        output << "module #{module_def.name}"

        # Module body
        body_parts = []

        # Add includes first (Ruby convention)
        module_def.includes.each do |include_mod|
          body_parts << "include #{include_mod}"
        end

        # Add extends
        module_def.extends.each do |extend_mod|
          body_parts << "extend #{extend_mod}"
        end

        # Add spacing after includes/extends if we have other content
        if (module_def.has_includes? || module_def.extends.any?) &&
           (module_def.has_attr_methods? || module_def.has_constants? || module_def.has_class_variables? || module_def.has_methods?)
          body_parts << ""
        end

        # Add attr_* methods
        body_parts.concat(format_attr_methods(module_def))

        # Add constants
        module_def.constants.each do |name, value|
          body_parts << "#{name} = #{normalize_constant_value(value)}"
        end

        # Add class variables
        module_def.class_variables.each do |name, value|
          body_parts << "#{name} = #{normalize_constant_value(value)}"
        end

        # Group methods by visibility
        public_methods = module_def.methods.select(&:public?)
        private_methods = module_def.methods.select(&:private?)
        protected_methods = module_def.methods.select(&:protected?)

        # Add public methods
        public_methods.each_with_index do |method, index|
          body_parts << "" if index > 0  # Add blank line between methods
          body_parts << convert_method(method, include_prose)
        end

        # Add private methods
        unless private_methods.empty?
          body_parts << ""
          body_parts << "private"
          body_parts << ""
          private_methods.each_with_index do |method, index|
            body_parts << "" if index > 0  # Add blank line between methods
            body_parts << convert_method(method, include_prose)
          end
        end

        # Add protected methods
        unless protected_methods.empty?
          body_parts << ""
          body_parts << "protected"
          body_parts << ""
          protected_methods.each_with_index do |method, index|
            body_parts << "" if index > 0  # Add blank line between methods
            body_parts << convert_method(method, include_prose)
          end
        end

        # Add aliases at the end
        if module_def.has_aliases?
          body_parts << ""
          module_def.aliases.each do |alias_name, original_method|
            body_parts << "alias #{alias_name} #{original_method}"
          end
          module_def.alias_methods.each do |alias_name, original_method|
            body_parts << "alias_method :#{alias_name}, :#{original_method}"
          end
        end

        # Format module body with proper indentation
        unless body_parts.empty?
          formatted_body = body_parts.map { |part|
            part.empty? ? "" : format_indentation(part)
          }.join("\n")
          output << formatted_body
        end

        output << "end"
        output.join("\n")
      end

      def convert_method(method, include_prose = false)
        output = []

        # Add method prose as comments if requested
        if include_prose && method.has_prose?
          method_prose = { method: method.prose }
          output << format_prose_as_comments(method_prose, 1)
        end

        # Method definition line
        method_prefix = method.class_method? ? "self." : ""
        method_args = format_method_arguments(method.arguments)
        method_line = "def #{method_prefix}#{method.name}#{method_args}"

        output << method_line

        # Method body
        if method.has_body?
          formatted_body = format_indentation(method.body)
          output << formatted_body
        end

        output << "end"
        output.join("\n")
      end

      def format_attr_methods(class_or_module)
        attr_parts = []

        unless class_or_module.attr_readers.empty?
          readers = format_attribute_list(class_or_module.attr_readers)
          attr_parts << "attr_reader #{readers}"
        end

        unless class_or_module.attr_writers.empty?
          writers = format_attribute_list(class_or_module.attr_writers)
          attr_parts << "attr_writer #{writers}"
        end

        unless class_or_module.attr_accessors.empty?
          accessors = format_attribute_list(class_or_module.attr_accessors)
          attr_parts << "attr_accessor #{accessors}"
        end

        attr_parts
      end
    end
  end
end
