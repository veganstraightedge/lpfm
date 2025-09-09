# frozen_string_literal: true

module LPFM
  module Data
    # Represents a Ruby method definition in LPFM
    class MethodDefinition
      attr_accessor :name, :arguments, :body, :visibility, :is_class_method, :prose

      def initialize(name, visibility: :public)
        @name = name
        @arguments = []
        @body = ""
        @visibility = visibility
        @is_class_method = false
        @prose = nil
      end

      def add_argument(arg)
        @arguments << arg
      end

      def set_body(body)
        @body = body.strip
      end

      def set_visibility(visibility)
        @visibility = visibility.to_sym
      end

      def make_class_method!
        @is_class_method = true
      end

      def class_method?
        @is_class_method
      end

      def instance_method?
        !@is_class_method
      end

      def private?
        @visibility == :private
      end

      def protected?
        @visibility == :protected
      end

      def public?
        @visibility == :public
      end

      def has_arguments?
        !@arguments.empty?
      end

      def has_body?
        !@body.empty?
      end

      def signature
        args_string = @arguments.empty? ? "" : "(#{@arguments.join(', ')})"
        method_prefix = @is_class_method ? "self." : ""
        "#{method_prefix}#{@name}#{args_string}"
      end

      def add_prose(text)
        @prose = text
      end

      def has_prose?
        !@prose.nil? && !@prose.empty?
      end
    end
  end
end
