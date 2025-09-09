# frozen_string_literal: true

require_relative 'base'

module LPFM
  module Parser
    # Parser for LPFM (Literate Programming Flavored Markdown) content
    class LPFM < Base
      def parse
        metadata, content_without_frontmatter = extract_yaml_frontmatter
        process_yaml_metadata(metadata) if metadata

        lines = split_into_lines(content_without_frontmatter)
        parse_structure(lines)

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

      def parse_structure(lines)
        current_class_or_module = nil
        current_method = nil
        current_visibility = :public
        content_buffer = []

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
              current_class_or_module = create_class_or_module(heading_info[:title])
              current_visibility = :public
              current_method = nil
            when 2
              # H2 defines method or visibility modifier
              if is_visibility_modifier?(heading_info[:title])
                current_visibility = heading_info[:title].strip.downcase.to_sym
                current_method = nil
              else
                current_method = create_method(heading_info[:title], current_visibility, current_class_or_module)
              end
            when 3
              # H3 defines method within current visibility scope
              if current_class_or_module
                current_method = create_method(heading_info[:title], current_visibility, current_class_or_module)
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

      def create_class_or_module(title)
        # Check metadata to determine if it's a module
        metadata = @lpfm_object.instance_variable_get(:@metadata) || {}
        is_module = metadata['type'] == 'module'

        if is_module
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

        # Process metadata attributes
        process_metadata_for_class_or_module(class_or_module, metadata)

        class_or_module
      end

      def process_metadata_for_class_or_module(class_or_module, metadata)
        return unless metadata

        # Handle attr_* methods
        if metadata['attr_reader']
          class_or_module.add_attr_reader(*Array(metadata['attr_reader']))
        end

        if metadata['attr_writer']
          class_or_module.add_attr_writer(*Array(metadata['attr_writer']))
        end

        if metadata['attr_accessor']
          class_or_module.add_attr_accessor(*Array(metadata['attr_accessor']))
        end

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
        # Parse class-level content like constants and class variables
        content.each_line do |line|
          line = line.strip
          next if line.empty?

          # Handle constants (CONSTANT_NAME = value)
          if line.match?(/^[A-Z][A-Z0-9_]*\s*=/)
            parts = line.split('=', 2)
            constant_name = parts[0].strip
            constant_value = parts[1].strip if parts[1]
            class_or_module.add_constant(constant_name, constant_value)

          # Handle class variables (@@var = value)
          elsif line.match?(/^@@\w+\s*=/)
            parts = line.split('=', 2)
            var_name = parts[0].strip
            var_value = parts[1].strip if parts[1]
            class_or_module.add_class_variable(var_name, var_value)
          end
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
