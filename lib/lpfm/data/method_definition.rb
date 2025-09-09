# frozen_string_literal: true

module LPFM
  module Data
    # Represents a Ruby method definition in LPFM
    class MethodDefinition
      attr_accessor :arguments, :body, :is_class_method, :is_singleton_method, :name, :prose, :visibility

      def initialize(name, visibility: :public)
        @name = name
        @arguments = []
        @body = ""
        @visibility = visibility
        @is_class_method = false
        @prose = nil
        @is_singleton_method = false
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

      def arguments?
        !@arguments.empty?
      end

      def body?
        !@body.empty?
      end

      def signature
        args_string = @arguments.empty? ? "" : "(#{@arguments.join(", ")})"
        method_prefix = @is_class_method ? "self." : ""
        "#{method_prefix}#{@name}#{args_string}"
      end

      def add_prose(text)
        @prose = text
      end

      def prose?
        !@prose.nil? && !@prose.empty?
      end

      def singleton_method?
        @is_singleton_method
      end

      def mark_as_singleton!
        @is_singleton_method = true
      end
    end
  end
end
