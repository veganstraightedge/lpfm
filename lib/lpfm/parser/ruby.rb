# frozen_string_literal: true

require "prism"
require_relative "foundation"

module LPFM
  module Parser
    # Parser for Ruby content using Prism AST
    class Ruby < Foundation
      def initialize(content, lpfm_object, filename = nil)
        super(content, lpfm_object)
        @filename = filename
      end

      def parse
        begin
          # Parse Ruby content with Prism
          result = Prism.parse(@content)

          if result.failure?
            errors = result.errors.map(&:message).join(", ")
            raise Error, "Failed to parse Ruby code: #{errors}"
          end

          # Convert AST to LPFM structure
          convert_ast_to_lpfm(result.value)
        rescue Prism::ParseError => e
          raise Error, "Ruby syntax error: #{e.message}"
        rescue StandardError => e
          raise Error, "Failed to parse Ruby content: #{e.message}"
        end

        @lpfm_object
      end

      private

      def convert_ast_to_lpfm(program_node)
        # Process top-level statements
        program_node.statements.body.each do |statement|
          process_statement(statement, nil, [])
        end
      end

      def process_statement(node, parent_class_or_module = nil, namespace_path = [])
        case node
        when Prism::ClassNode
          process_class_node(node, namespace_path)
        when Prism::ModuleNode
          process_module_node(node, namespace_path)
        when Prism::SingletonClassNode
          process_singleton_class_node(node, parent_class_or_module)
        when Prism::DefNode
          # Top-level method (should be rare, but handle it)
          process_method_node(node, parent_class_or_module) if parent_class_or_module
        when Prism::CallNode
          process_call_node(node, parent_class_or_module)
        when Prism::ConstantWriteNode, Prism::ConstantPathWriteNode
          process_constant_assignment(node, parent_class_or_module)
        when Prism::InstanceVariableWriteNode
          process_instance_variable_assignment(node, parent_class_or_module)
        when Prism::ClassVariableWriteNode
          process_class_variable_assignment(node, parent_class_or_module)
        when Prism::AliasMethodNode
          process_alias_statement(node, parent_class_or_module)
          # Skip comments and other nodes that don't translate to LPFM structure
        end
      end

      def process_class_node(node, namespace_path = [])
        class_name = extract_constant_name(node.constant_path)

        # Handle inheritance
        superclass = nil
        superclass = extract_constant_name(node.superclass) if node.superclass

        # Create class in LPFM at top level but with namespace information
        @lpfm_object.add_class(class_name)
        class_def = @lpfm_object.get_class(class_name)
        class_def.inherits_from = superclass if superclass

        # Set namespace if we're inside modules
        class_def.instance_variable_set(:@namespace, namespace_path.dup) unless namespace_path.empty?

        # Process class body
        return unless node.body

        current_visibility = :public
        node.body.body.each do |statement|
          case statement
          when Prism::CallNode
            # Handle visibility modifiers and method calls
            if is_visibility_call?(statement)
              current_visibility = extract_visibility(statement)
            else
              process_call_node(statement, class_def)
            end
          when Prism::DefNode
            # Instance method
            method = process_method_node(statement, class_def)
            method&.set_visibility(current_visibility)
          else
            process_statement(statement, class_def, namespace_path + [class_name])
          end
        end
      end

      def process_module_node(node, namespace_path = [])
        module_name = extract_constant_name(node.constant_path)

        # Create module in LPFM at top level but with namespace information
        @lpfm_object.add_module(module_name)
        module_def = @lpfm_object.get_module(module_name)

        # Set namespace if we're inside other modules
        module_def.instance_variable_set(:@namespace, namespace_path.dup) unless namespace_path.empty?

        # Track if this module has its own content (not just nested modules/classes)
        has_own_content = false

        # Process module body
        if node.body
          current_visibility = :public
          node.body.body.each do |statement|
            case statement
            when Prism::CallNode
              if is_visibility_call?(statement)
                current_visibility = extract_visibility(statement)
              else
                process_call_node(statement, module_def)
              end
              has_own_content = true
            when Prism::DefNode
              method = process_method_node(statement, module_def)
              method&.set_visibility(current_visibility)
              has_own_content = true
            when Prism::ClassNode, Prism::ModuleNode
              # Nested class or module - don't count as own content
              process_statement(statement, module_def, namespace_path + [module_name])
            else
              process_statement(statement, module_def, namespace_path + [module_name])
              has_own_content = true
            end
          end
        end

        # If this module only contains nested modules/classes, mark it as namespace-only
        module_def.instance_variable_set(:@is_namespace, true) unless has_own_content
      end

      def process_singleton_class_node(node, parent_class_or_module)
        return unless parent_class_or_module

        # Process the body of the class << self block
        node.body&.body&.each do |statement|
          case statement
          when Prism::DefNode
            # Mark method as singleton method
            method = process_method_node(statement, parent_class_or_module)
            method&.instance_variable_set(:@is_singleton_method, true)
          else
            process_statement(statement, parent_class_or_module)
          end
        end
      end

      def process_method_node(node, parent_class_or_module)
        return nil unless parent_class_or_module

        method_name = node.name.to_s

        # Check if it's a class method or singleton method
        is_class_method = false
        if node.receiver
          case node.receiver.type
          when :self_node
            is_class_method = true
            method_name = method_name.sub(/^self\./, "")
          when :call_node
            # Handle def object.method syntax (like def admin.revoke_access)
            receiver_name = node.receiver.name.to_s
            method_name = "#{receiver_name}.#{method_name}"
          end
        end

        # Extract method arguments
        arguments = extract_method_parameters(node.parameters)

        # Create method
        method = Data::MethodDefinition.new(method_name, visibility: :public)
        arguments.each { |arg| method.add_argument(arg) }
        method.make_class_method! if is_class_method

        # Extract method body
        if node.body
          body = extract_method_body(node.body)
          method.set_body(body)
        end

        parent_class_or_module.add_method(method)
        method
      end

      def process_call_node(node, parent_class_or_module)
        return unless node.name

        method_name = node.name.to_s

        case method_name
        when "require"
          handle_require_call(node)
        when "include"
          handle_include_call(node, parent_class_or_module)
        when "extend"
          handle_extend_call(node, parent_class_or_module)
        when "attr_reader", "attr_writer", "attr_accessor"
          handle_attr_call(node, parent_class_or_module, method_name)
        when "alias_method"
          handle_alias_method_call(node, parent_class_or_module)
        when "private", "protected", "public"
          # These are handled in the method processing loop
          nil
        end
      end

      def handle_require_call(node)
        # Extract require argument
        return unless node.arguments&.arguments&.first&.type == :string_node

        requirement = node.arguments.arguments.first.unescaped
        @lpfm_object.add_require(requirement)
      end

      def handle_include_call(node, parent_class_or_module)
        return unless parent_class_or_module

        return unless node.arguments&.arguments&.first

        module_name = extract_constant_name(node.arguments.arguments.first)
        parent_class_or_module.add_include(module_name) if module_name
      end

      def handle_extend_call(node, parent_class_or_module)
        return unless parent_class_or_module

        return unless node.arguments&.arguments&.first

        module_name = extract_constant_name(node.arguments.arguments.first)
        parent_class_or_module.add_extend(module_name) if module_name
      end

      def handle_attr_call(node, parent_class_or_module, attr_type)
        return unless parent_class_or_module && node.arguments

        symbols = []
        node.arguments.arguments.each do |arg|
          symbols << arg.unescaped.to_sym if arg.type == :symbol_node
        end

        return if symbols.empty?

        # Use inline attrs to preserve order and spacing

        attr_symbol = {
          "attr_reader"   => :reader,
          "attr_writer"   => :writer,
          "attr_accessor" => :accessor
        }[attr_type]

        parent_class_or_module.add_inline_attr(attr_symbol, symbols)
      end

      def handle_alias_method_call(node, parent_class_or_module)
        return unless parent_class_or_module && node.arguments

        args = node.arguments.arguments
        return unless args.length == 2

        alias_name = extract_symbol_value(args[0])
        original_name = extract_symbol_value(args[1])

        parent_class_or_module.add_alias_method(alias_name, original_name) if alias_name && original_name
      end

      def process_constant_assignment(node, parent_class_or_module)
        return unless parent_class_or_module

        constant_name = case node
                        when Prism::ConstantWriteNode
                          node.name.to_s
                        when Prism::ConstantPathWriteNode
                          extract_constant_name(node.target)
                        end

        return unless constant_name

        value = extract_literal_value(node.value)
        parent_class_or_module.add_constant(constant_name, value)
      end

      def process_class_variable_assignment(node, parent_class_or_module)
        return unless parent_class_or_module

        var_name = node.name.to_s
        value = extract_literal_value(node.value)
        parent_class_or_module.add_class_variable(var_name, value)
      end

      def extract_constant_name(node)
        case node
        when Prism::ConstantReadNode
          node.name.to_s
        when Prism::ConstantPathNode
          parts = []
          collect_constant_path_parts(node, parts)
          parts.join("::")
        when Prism::SelfNode
          "self"
        else
          node.to_s if node.respond_to?(:to_s)
        end
      end

      def collect_constant_path_parts(node, parts)
        case node
        when Prism::ConstantPathNode
          collect_constant_path_parts(node.parent, parts) if node.parent
          parts << node.name.to_s
        when Prism::ConstantReadNode
          parts << node.name.to_s
        end
      end

      def extract_method_parameters(params_node)
        return [] unless params_node

        # Required parameters
        parameters = params_node.requireds.map do |param|
          param.name.to_s
        end

        # Optional parameters with defaults
        params_node.optionals.each do |param|
          default_value = extract_literal_value(param.value)
          parameters << if default_value.nil?
                          "#{param.name} = #{param.value.slice}"
                        else
                          "#{param.name} = #{format_parameter_default(default_value)}"
                        end
        end

        # Rest parameter (*args)
        if params_node.rest && !params_node.rest.name.nil?
          parameters << "*#{params_node.rest.name}"
        elsif params_node.rest
          parameters << "*"
        end

        # Keyword parameters
        params_node.keywords.each do |param|
          case param
          when Prism::RequiredKeywordParameterNode
            parameters << "#{param.name}:"
          when Prism::OptionalKeywordParameterNode
            if param.value
              default_value = extract_literal_value(param.value)
              parameters << if default_value.nil?
                              "#{param.name}: #{param.value.slice}"
                            else
                              "#{param.name}: #{format_parameter_default(default_value)}"
                            end
            else
              parameters << "#{param.name}:"
            end
          else
            # Fallback for other keyword parameter types
            parameters << "#{param.name}:"
          end
        end

        # Keyword rest parameter (**kwargs)
        if params_node.keyword_rest&.name
          parameters << "**#{params_node.keyword_rest.name}"
        elsif params_node.keyword_rest
          parameters << "**"
        end

        # Block parameter (&block)
        parameters << "&#{params_node.block.name}" if params_node.block

        parameters
      end

      def extract_method_body(body_node)
        return "" unless body_node

        case body_node
        when Prism::StatementsNode
          if body_node.body.empty?
            ""
          else
            # Get the full range of the method body
            start_offset = body_node.body.first.location.start_offset
            end_offset = body_node.body.last.location.end_offset

            # Extract the entire body as one block
            body_content = @content[start_offset...end_offset]

            # Split into lines and normalize indentation
            lines = body_content.split("\n")

            # Find minimum indentation of non-empty lines
            non_empty_lines = lines.reject { |line| line.strip.empty? }
            if non_empty_lines.empty?
              ""
            else
              # Special case: if first line has no indentation but others do,
              # it means first line starts right after method definition
              # We need to normalize all lines to have consistent base indentation
              first_indent = non_empty_lines.first[/^\s*/].length

              if non_empty_lines.length > 1
                other_indents = non_empty_lines[1..].map { |line| line[/^\s*/].length }
                min_other_indent = other_indents.min || 0

                if first_indent.zero? && min_other_indent.positive?
                  # Remove the extra indentation from all lines after the first
                  normalized_lines = lines.map do |line|
                    if line.strip.empty?
                      ""
                    elsif line == lines.first
                      line # Keep first line as-is
                    else
                      line.length > min_other_indent ? line[min_other_indent..] : line.lstrip
                    end
                  end
                else
                  # Normal case - remove minimum indentation from all lines
                  min_indent = non_empty_lines.map { |line| line[/^\s*/].length }.min
                  normalized_lines = lines.map do |line|
                    if line.strip.empty?
                      ""
                    else
                      line.length > min_indent ? line[min_indent..] : line.lstrip
                    end
                  end
                end
              else
                # Single line - just strip
                normalized_lines = [non_empty_lines.first.strip]
              end

              normalized_lines.join("\n").strip
            end
          end
        else
          # Single expression
          body_node.slice.strip
        end
      end

      def extract_literal_value(node)
        case node
        when Prism::StringNode
          node.unescaped
        when Prism::IntegerNode
          node.value
        when Prism::FloatNode
          node.value
        when Prism::TrueNode
          true
        when Prism::FalseNode
          false
        when Prism::NilNode
          nil
        when Prism::SymbolNode
          node.unescaped.to_sym
        end
      end

      def extract_symbol_value(node)
        case node
        when Prism::SymbolNode
          node.unescaped
        when Prism::StringNode
          node.unescaped
        end
      end

      def format_parameter_default(value)
        case value
        when String
          "\"#{value}\""
        when Symbol
          ":#{value}"
        else
          value.inspect
        end
      end

      def is_visibility_call?(node)
        return false unless node.type == :call_node
        return false unless node.receiver.nil? # Should be a bare method call

        %w[private protected public].include?(node.name.to_s)
      end

      def extract_visibility(node)
        node.name.to_s.to_sym
      end

      def process_alias_statement(node, parent_class_or_module)
        return unless parent_class_or_module

        alias_name = extract_symbol_value(node.new_name)
        original_name = extract_symbol_value(node.old_name)

        parent_class_or_module.add_alias(alias_name, original_name) if alias_name && original_name
      end
    end
  end
end
