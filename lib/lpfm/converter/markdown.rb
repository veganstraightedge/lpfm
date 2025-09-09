# frozen_string_literal: true

require_relative 'foundation'

module LPFM
  module Converter
    # Converter for generating Markdown with fenced Ruby code blocks from LPFM internal structure
    class Markdown < Foundation
      def convert(include_prose: true)
        return "" unless has_content?

        output = []

        # Generate single fenced code block with all Ruby code
        ruby_code = generate_all_ruby_code

        if !ruby_code.empty?
          output << "```ruby"
          output << ruby_code
          output << "```"
        end

        output.join("\n")
      end

      def generate_all_ruby_code
        output = []

        # Add requires at the top
        requires_output = format_requires(@lpfm_object.requires)
        if !requires_output.empty?
          output << requires_output.rstrip
          output << ""
        end

        # Group classes and modules by namespace
        namespace_groups = {}
        standalone_items = []

        # Group classes by namespace
        @lpfm_object.classes.each do |name, class_def|
          namespace = class_def.namespace
          if namespace && !namespace.empty?
            namespace_key = namespace.join('::')
            namespace_groups[namespace_key] ||= { modules: [], classes: [] }
            namespace_groups[namespace_key][:classes] << class_def
          else
            standalone_items << { type: :class, item: class_def }
          end
        end

        # Group modules by namespace (excluding namespace modules themselves)
        @lpfm_object.modules.each do |name, module_def|
          unless module_def.is_namespace?
            namespace = module_def.namespace
            if namespace && !namespace.empty?
              namespace_key = namespace.join('::')
              namespace_groups[namespace_key] ||= { modules: [], classes: [] }
              namespace_groups[namespace_key][:modules] << module_def
            else
              standalone_items << { type: :module, item: module_def }
            end
          end
        end

        # Generate namespaced items
        namespace_groups.each_with_index do |(namespace_key, items), index|
          output << "" if index > 0 || (!requires_output.empty? && !standalone_items.empty?)
          namespace_parts = namespace_key.split('::')

          # Open namespace modules with proper nesting
          namespace_parts.each_with_index do |ns, depth|
            indent = "  " * depth
            output << "#{indent}module #{ns}"
          end

          # Add classes and modules within namespace
          all_items = items[:modules] + items[:classes]
          all_items.each_with_index do |item, item_index|
            output << "" if item_index > 0

            if item.is_a?(Data::ClassDefinition)
              content = generate_class_content(item)
            else
              content = generate_module_content(item)
            end

            # Indent content for all namespace levels
            base_indent = "  " * namespace_parts.length
            content.split("\n").each do |line|
              output << (line.empty? ? "" : "#{base_indent}#{line}")
            end
          end

          # Close namespace modules in reverse order with proper indentation
          namespace_parts.reverse.each_with_index do |_, index|
            depth = namespace_parts.length - 1 - index
            indent = "  " * depth
            output << "#{indent}end"
          end
        end

        # Add standalone items
        standalone_items.each_with_index do |item_info, index|
          output << "" if index > 0 || (!namespace_groups.empty? && index == 0)

          if item_info[:type] == :class
            output << generate_class_content(item_info[:item])
          else
            output << generate_module_content(item_info[:item])
          end
        end

        output.join("\n")
      end

      private

      def generate_class_content(class_def)
        output = []

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

        # Add spacing after includes/extends if we have constants, class variables, attrs, or methods
        has_includes_or_extends = class_def.has_includes? || class_def.extends.any?
        has_constants_or_vars = class_def.has_constants? || class_def.has_class_variables?
        has_attrs = class_def.has_attr_methods?

        if has_includes_or_extends && (has_constants_or_vars || has_attrs || class_def.has_methods?)
          body_parts << ""
        end

        # Add class variables
        class_def.class_variables.each do |name, value|
          body_parts << "#{name} = #{normalize_constant_value(value)}"
        end

        # Add constants
        class_def.constants.each do |name, value|
          body_parts << "#{name} = #{normalize_constant_value(value)}"
        end

        # Add spacing after constants/class_variables if we have attr methods or methods
        if (class_def.has_constants? || class_def.has_class_variables?) &&
           (class_def.has_attr_methods? || class_def.has_methods?)
          body_parts << ""
        end

        # Add attr_* methods (YAML first, then inline in order)
        yaml_attrs = format_attr_methods(class_def)
        inline_attrs = format_inline_attr_methods(class_def)

        body_parts.concat(yaml_attrs)

        body_parts.concat(inline_attrs)

        # Add spacing after any attr methods if we have methods (but not aliases, since they handle their own spacing)
        has_methods = class_def.has_methods?
        has_any_attrs = !yaml_attrs.empty? || !inline_attrs.empty?
        if has_any_attrs && has_methods
          body_parts << ""
        end

        # Process methods in their original parse order, handling singleton blocks and visibility changes
        current_visibility = :public
        method_index = 0
        in_singleton_block = false
        singleton_methods = []

        class_def.methods.each do |method|
          if method.singleton_method?
            # This is a class method from class << self block
            if !in_singleton_block
              # Start the singleton block
              body_parts << "" if method_index > 0
              body_parts << "class << self"
              in_singleton_block = true
            end
            singleton_methods << method
          else
            # Close singleton block if we're in one and this is not a singleton method
            if in_singleton_block
              singleton_methods.each_with_index do |singleton_method, index|
                body_parts << "" if index > 0
                body_parts << convert_method(singleton_method).split("\n").map { |line| line.empty? ? "" : "  #{line}" }.join("\n")
              end
              body_parts << "end"
              singleton_methods.clear
              in_singleton_block = false
              method_index += 1
            end

            # Add spacing before method if this isn't the first method
            body_parts << "" if method_index > 0

            # Check if we need to add a visibility modifier
            if method.visibility != current_visibility
              body_parts << method.visibility.to_s
              body_parts << ""
              current_visibility = method.visibility
            end

            body_parts << convert_method(method)
          end

          method_index += 1
        end

        # Close singleton block if we ended while still in one
        if in_singleton_block
          singleton_methods.each_with_index do |singleton_method, index|
            body_parts << "" if index > 0
            body_parts << convert_method(singleton_method).split("\n").map { |line| line.empty? ? "" : "  #{line}" }.join("\n")
          end
          body_parts << "end"
        end

        # Add aliases at the end
        if class_def.has_aliases?
          # Only add spacing if there are attrs or methods before aliases
          has_any_attrs = !yaml_attrs.empty? || !inline_attrs.empty?
          if has_any_attrs || class_def.has_methods?
            body_parts << ""
          end
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

      def generate_module_content(module_def)
        output = []

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

        # Add constants first
        module_def.constants.each do |name, value|
          body_parts << "#{name} = #{normalize_constant_value(value)}"
        end

        # Add spacing after constants if we have attr methods
        if module_def.has_constants? && module_def.has_attr_methods?
          body_parts << ""
        end

        # Add attr_* methods (YAML first, then inline in order)
        yaml_attrs = format_attr_methods(module_def)
        inline_attrs = format_inline_attr_methods(module_def)
        body_parts.concat(yaml_attrs)
        body_parts.concat(inline_attrs)

        # Add spacing after any attr methods if we have methods or class variables (but not aliases, since they handle their own spacing)
        has_methods_or_vars = module_def.has_methods? || !module_def.class_variables.empty?
        has_any_attrs = !yaml_attrs.empty? || !inline_attrs.empty?
        if has_any_attrs && has_methods_or_vars
          body_parts << ""
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
          body_parts << convert_method(method)
        end

        # Add protected methods first (as they appear first in LPFM)
        unless protected_methods.empty?
          body_parts << ""
          body_parts << "protected"
          body_parts << ""
          protected_methods.each_with_index do |method, index|
            body_parts << "" if index > 0  # Add blank line between methods
            body_parts << convert_method(method)
          end
        end

        # Add private methods
        unless private_methods.empty?
          body_parts << ""
          body_parts << "private"
          body_parts << ""
          private_methods.each_with_index do |method, index|
            body_parts << "" if index > 0  # Add blank line between methods
            body_parts << convert_method(method)
          end
        end

        # Add aliases at the end
        if module_def.has_aliases?
          # Only add spacing if there are attrs, methods, or class variables before aliases
          has_any_attrs = !yaml_attrs.empty? || !inline_attrs.empty?
          if has_any_attrs || module_def.has_methods? || !module_def.class_variables.empty?
            body_parts << ""
          end
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

      def convert_method(method)
        output = []

        # Method definition line
        # Don't add self. prefix for object singleton methods that already contain dots
        method_prefix = if method.class_method? && !method.name.include?('.')
                         "self."
                        else
                         ""
                        end
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

        # Check traditional arrays first
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

        # If traditional arrays are empty but we have inline_attrs, use those as YAML attrs
        if attr_parts.empty?
          inline_attrs = class_or_module.inline_attrs
          if inline_attrs && !inline_attrs.empty?
            inline_attrs.each do |attr_info|
              case attr_info[:type]
              when :reader
                readers = format_attribute_list(attr_info[:attrs])
                attr_parts << "attr_reader #{readers}"
              when :writer
                writers = format_attribute_list(attr_info[:attrs])
                attr_parts << "attr_writer #{writers}"
              when :accessor
                accessors = format_attribute_list(attr_info[:attrs])
                attr_parts << "attr_accessor #{accessors}"
              end
            end
          end
        end

        attr_parts
      end

      def format_inline_attr_methods(class_or_module)
        # Only return inline attrs if we also have traditional attrs
        # (Otherwise inline_attrs are treated as YAML attrs by format_attr_methods)
        has_traditional_attrs = !class_or_module.attr_readers.empty? ||
                               !class_or_module.attr_writers.empty? ||
                               !class_or_module.attr_accessors.empty?

        return [] unless has_traditional_attrs

        inline_attrs = class_or_module.inline_attrs
        return [] unless inline_attrs && !inline_attrs.empty?

        attr_parts = []

        inline_attrs.each do |attr_info|
          case attr_info[:type]
          when :reader
            readers = format_attribute_list(attr_info[:attrs])
            attr_parts << "attr_reader #{readers}"
          when :writer
            writers = format_attribute_list(attr_info[:attrs])
            attr_parts << "attr_writer #{writers}"
          when :accessor
            accessors = format_attribute_list(attr_info[:attrs])
            attr_parts << "attr_accessor #{accessors}"
          end
        end

        attr_parts
      end
    end
  end
end
