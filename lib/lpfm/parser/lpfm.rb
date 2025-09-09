# frozen_string_literal: true

require_relative 'base'

module LPFM
  module Parser
    # Parser for LPFM (Literate Programming Flavored Markdown) content
    class LPFM < Base
      def initialize(content, lpfm_object, filename = nil)
        super(content, lpfm_object)
        @filename = filename
      end

      def parse
        metadata, content_without_frontmatter = extract_yaml_frontmatter
        process_yaml_metadata(metadata) if metadata

        lines = split_into_lines(content_without_frontmatter)
        parse_structure(lines, metadata)

        @lpfm_object
      end

      private

      def process_yaml_metadata(metadata)
        # Handle requires
        if metadata['require']
          Array(metadata['require']).each { |req| @lpfm_object.add_require(req) }
        end

        # Store metadata for later use
        @lpfm_object.instance_variable_set(:@metadata, metadata)
      end

      def parse_structure(lines, metadata = nil)
        current_class_or_module = nil
        current_method = nil
        current_visibility = :public
        content_buffer = []
        has_h1_heading = lines.any? { |line| extract_heading_info(line)&.dig(:level) == 1 }

        # If no H1 heading and we have content, infer from filename
        if !has_h1_heading && @filename && lines.any? { |line| !is_empty_line?(line) }
          inferred_name = infer_class_name_from_filename(@filename)
          if inferred_name
            current_class_or_module = create_class_or_module(inferred_name, metadata)
          end
        end

        i = 0
        while i < lines.length
          line = lines[i]

          if is_empty_line?(line)
            content_buffer << line
            i += 1
            next
          end

          heading_info = extract_heading_info(line)

          if heading_info
            # Process any accumulated content before this heading
            process_content_buffer(content_buffer, current_method, current_class_or_module)
            content_buffer.clear

            case heading_info[:level]
            when 1
              # H1 defines class or module
              current_class_or_module = create_class_or_module(heading_info[:title], metadata)
              current_visibility = :public
              current_method = nil
            when 2
              # H2 defines method, visibility modifier, or singleton class block
              if is_visibility_modifier?(heading_info[:title])
                current_visibility = heading_info[:title].strip.downcase.to_sym
                current_method = nil
                # Exit singleton block when we hit a visibility modifier
                current_class_or_module.instance_variable_set(:@in_singleton_block, false)
              elsif heading_info[:title].strip == 'class << self'
                # Handle singleton class block - methods following will be class methods
                current_visibility = :public
                current_method = nil
                # Mark that we're in a singleton class context
                current_class_or_module.instance_variable_set(:@in_singleton_block, true)
              else
                # Exit singleton block when we encounter a regular H2 method
                current_class_or_module.instance_variable_set(:@in_singleton_block, false)
                current_method = create_method(heading_info[:title], current_visibility, current_class_or_module)
              end
            when 3
              # H3 defines method within current visibility scope or singleton block
              if current_class_or_module
                current_method = create_method(heading_info[:title], current_visibility, current_class_or_module)
                # If we're in a singleton block, mark this method as a singleton method
                if current_class_or_module.instance_variable_get(:@in_singleton_block)
                  current_method.instance_variable_set(:@is_singleton_method, true)
                end
              end
            end
          else
            # Regular content line
            content_buffer << line
          end

          i += 1
        end

        # Process any remaining content
        process_content_buffer(content_buffer, current_method, current_class_or_module)
      end

      def create_class_or_module(title, metadata = nil)
        # Use provided metadata or get from LPFM object
        metadata ||= @lpfm_object.instance_variable_get(:@metadata) || {}

        # Check if title starts with "module" keyword
        if title.start_with?('module ')
          module_name = title.sub(/^module\s+/, '')
          @lpfm_object.add_module(module_name)
          class_or_module = @lpfm_object.get_module(module_name)
        elsif title.start_with?('class ')
          class_name = title.sub(/^class\s+/, '')
          @lpfm_object.add_class(class_name)
          class_or_module = @lpfm_object.get_class(class_name)
        elsif title.include?('::')
          # Handle namespaced classes/modules
          class_or_module = create_namespaced_class_or_module(title, metadata)
        elsif metadata['type'] == 'module'
          @lpfm_object.add_module(title)
          class_or_module = @lpfm_object.get_module(title)
        else
          @lpfm_object.add_class(title)
          class_or_module = @lpfm_object.get_class(title)

          # Handle inheritance
          if metadata['inherits_from']
            class_or_module.inherits_from = metadata['inherits_from']
          end
        end

        # Process metadata attributes if we have a single class/module
        if class_or_module
          process_metadata_for_class_or_module(class_or_module, metadata)
        end

        class_or_module
      end

      def create_namespaced_class_or_module(title, metadata)
        # Split namespace from class name: "MyApp::UserService" -> ["MyApp", "UserService"]
        parts = title.split('::')
        class_name = parts.pop
        namespace_parts = parts

        # Create nested modules for namespace
        namespace_parts.each do |namespace|
          unless @lpfm_object.get_module(namespace)
            @lpfm_object.add_module(namespace)
            # Mark this as a namespace module
            namespace_module = @lpfm_object.get_module(namespace)
            namespace_module.instance_variable_set(:@is_namespace, true)
          end
        end

        # Create the actual class
        if metadata['type'] == 'module'
          @lpfm_object.add_module(class_name)
          class_or_module = @lpfm_object.get_module(class_name)
        else
          @lpfm_object.add_class(class_name)
          class_or_module = @lpfm_object.get_class(class_name)
        end

        # Store namespace information
        class_or_module.instance_variable_set(:@namespace, namespace_parts)

        # Handle inheritance
        if metadata['inherits_from']
          class_or_module.inherits_from = metadata['inherits_from']
        end

        class_or_module
      end

      def process_metadata_for_class_or_module(class_or_module, metadata)
        return unless metadata

        # Process attr_* methods in the correct order to match expected output
        # Collect all attrs by type in the order they should appear
        attr_readers = []
        attr_writers = []
        attr_accessors = []

        # Process nested attr syntax first (name comes from here)
        if metadata['attr']
          attr_config = metadata['attr']
          attr_readers.concat(Array(attr_config['reader'])) if attr_config['reader']
          attr_writers.concat(Array(attr_config['writer'])) if attr_config['writer']
          attr_accessors.concat(Array(attr_config['accessor'])) if attr_config['accessor']
        end

        # Then add top-level attrs (id comes from here)
        attr_readers.concat(Array(metadata['attr_reader'])) if metadata['attr_reader']
        attr_writers.concat(Array(metadata['attr_writer'])) if metadata['attr_writer']
        attr_accessors.concat(Array(metadata['attr_accessor'])) if metadata['attr_accessor']

        # Add them to the class/module
        class_or_module.add_attr_reader(*attr_readers) unless attr_readers.empty?
        class_or_module.add_attr_writer(*attr_writers) unless attr_writers.empty?
        class_or_module.add_attr_accessor(*attr_accessors) unless attr_accessors.empty?

        # Handle includes and extends
        if metadata['include']
          Array(metadata['include']).each { |mod| class_or_module.add_include(mod) }
        end

        if metadata['extend']
          Array(metadata['extend']).each { |mod| class_or_module.add_extend(mod) }
        end

        # Handle constants
        if metadata['constants']
          metadata['constants'].each { |name, value| class_or_module.add_constant(name, value) }
        end

        # Handle class variables
        if metadata['class_variables']
          metadata['class_variables'].each { |name, value| class_or_module.add_class_variable("@@#{name}", value) }
        end

        # Handle aliases
        if metadata['aliases']
          metadata['aliases'].each { |alias_name, original_method| class_or_module.add_alias(alias_name, original_method) }
        end

        # Handle alias_method
        if metadata['alias_method']
          metadata['alias_method'].each { |alias_name, original_method| class_or_module.add_alias_method(alias_name, original_method) }
        end
      end

      def create_method(title, visibility, class_or_module)
        return nil unless class_or_module

        method_name = clean_method_name(title)
        arguments = extract_method_arguments(title)
        is_class_method = is_class_method?(title)

        method = Data::MethodDefinition.new(method_name, visibility: visibility)
        arguments.each { |arg| method.add_argument(arg) }
        method.make_class_method! if is_class_method

        class_or_module.add_method(method)
        method
      end

      def process_content_buffer(content_buffer, current_method, current_class_or_module)
        return if content_buffer.empty?

        content = content_buffer.join("\n").strip
        return if content.empty?

        if current_method
          # Content belongs to the current method
          current_method.set_body(content)
        elsif current_class_or_module
          # Content belongs to the class/module but not to a specific method
          # This could be constants, class variables, etc.
          process_class_level_content(content, current_class_or_module)
        end
      end

      def process_class_level_content(content, class_or_module)
        # Parse class-level content like constants, class variables, and attr_* methods
        # Store inline attrs separately to preserve ordering
        content.each_line do |line|
          line = line.strip
          next if line.empty?

          # Handle attr_reader - store as inline
          if line.match?(/^attr_reader\s+/)
            attrs = extract_attr_symbols(line)
            # Store inline attrs with metadata to preserve order
            class_or_module.instance_variable_set(:@inline_attrs, []) unless class_or_module.instance_variable_get(:@inline_attrs)
            class_or_module.instance_variable_get(:@inline_attrs) << { type: :reader, attrs: attrs }

          # Handle attr_writer - store as inline
          elsif line.match?(/^attr_writer\s+/)
            attrs = extract_attr_symbols(line)
            class_or_module.instance_variable_set(:@inline_attrs, []) unless class_or_module.instance_variable_get(:@inline_attrs)
            class_or_module.instance_variable_get(:@inline_attrs) << { type: :writer, attrs: attrs }

          # Handle attr_accessor - store as inline
          elsif line.match?(/^attr_accessor\s+/)
            attrs = extract_attr_symbols(line)
            class_or_module.instance_variable_set(:@inline_attrs, []) unless class_or_module.instance_variable_get(:@inline_attrs)
            class_or_module.instance_variable_get(:@inline_attrs) << { type: :accessor, attrs: attrs }

          # Handle constants (CONSTANT_NAME = value)
          elsif line.match?(/^[A-Z][A-Z0-9_]*\s*=/)
            parts = line.split('=', 2)
            constant_name = parts[0].strip
            constant_value = normalize_constant_value_from_text(parts[1].strip) if parts[1]
            class_or_module.add_constant(constant_name, constant_value)

          # Handle class variables (@@var = value)
          elsif line.match?(/^@@\w+\s*=/)
            parts = line.split('=', 2)
            var_name = parts[0].strip
            var_value = normalize_constant_value_from_text(parts[1].strip) if parts[1]
            class_or_module.add_class_variable(var_name, var_value)
          end
        end
      end

      def extract_attr_symbols(line)
        # Extract symbols from attr_* lines like "attr_reader :name, :email"
        symbols_part = line.sub(/^attr_\w+\s+/, '')
        symbols_part.split(',').map do |symbol|
          symbol.strip.sub(/^:/, '').to_sym
        end
      end

      def normalize_constant_value_from_text(value_text)
        value_text = value_text.strip

        # Handle numeric values
        if value_text.match?(/^\d+$/)
          value_text.to_i
        elsif value_text.match?(/^\d+\.\d+$/)
          value_text.to_f
        # Handle boolean values
        elsif value_text == 'true'
          true
        elsif value_text == 'false'
          false
        elsif value_text == 'nil'
          nil
        else
          # Return as string, preserving quotes if present
          value_text
        end
      end

      def infer_class_name_from_filename(filename)
        return nil unless filename

        base_name = File.basename(filename, '.*')
        # Convert snake_case to CamelCase
        base_name.split('_').map(&:capitalize).join
      end
    end
  end
end
