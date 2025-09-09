# frozen_string_literal: true

module LPFM
  module Data
    # Represents a Ruby class definition in LPFM
    class ClassDefinition
      attr_accessor :name, :inherits_from, :methods, :constants, :class_variables,
                    :attr_readers, :attr_writers, :attr_accessors, :includes, :extends,
                    :aliases, :alias_methods, :visibility_sections, :prose, :namespace,
                    :inline_attrs, :is_namespace, :in_singleton_block

      def initialize(name)
        @name = name
        @inherits_from = nil
        @methods = []
        @constants = {}
        @class_variables = {}
        @attr_readers = []
        @attr_writers = []
        @attr_accessors = []
        @includes = []
        @extends = []
        @aliases = {}
        @alias_methods = {}
        @visibility_sections = { public: [], private: [], protected: [] }
        @prose = {}
        @namespace = nil
        @inline_attrs = []
        @is_namespace = false
        @in_singleton_block = false
      end

      def add_method(method_definition)
        @methods << method_definition
      end

      def add_constant(name, value)
        @constants[name] = value
      end

      def add_class_variable(name, value)
        @class_variables[name] = value
      end

      def add_attr_reader(*names)
        @attr_readers.concat(names.flatten.map(&:to_sym))
      end

      def add_attr_writer(*names)
        @attr_writers.concat(names.flatten.map(&:to_sym))
      end

      def add_attr_accessor(*names)
        @attr_accessors.concat(names.flatten.map(&:to_sym))
      end

      def add_include(module_name)
        @includes << module_name unless @includes.include?(module_name)
      end

      def add_extend(module_name)
        @extends << module_name unless @extends.include?(module_name)
      end

      def add_prose(section, text)
        @prose[section] = text
      end

      def has_methods?
        !@methods.empty?
      end

      def has_constants?
        !@constants.empty?
      end

      def has_class_variables?
        !@class_variables.empty?
      end

      def has_attr_methods?
        has_traditional_attrs = !@attr_readers.empty? || !@attr_writers.empty? || !@attr_accessors.empty?
        has_inline_attrs = @inline_attrs && !@inline_attrs.empty?
        has_traditional_attrs || has_inline_attrs
      end

      def has_includes?
        !@includes.empty?
      end

      def has_extends?
        !@extends.empty?
      end

      def add_alias(alias_name, original_method)
        @aliases[alias_name] = original_method
      end

      def add_alias_method(alias_name, original_method)
        @alias_methods[alias_name] = original_method
      end

      def has_aliases?
        !@aliases.empty? || !@alias_methods.empty?
      end

      def add_inline_attr(type, attrs)
        @inline_attrs << { type: type, attrs: attrs }
      end

      def inline_attrs
        @inline_attrs ||= []
      end

      def namespace
        @namespace ||= []
      end

      def namespace=(value)
        @namespace = value
      end

      def is_namespace?
        @is_namespace
      end

      def mark_as_namespace!
        @is_namespace = true
      end

      def in_singleton_block?
        @in_singleton_block
      end

      def enter_singleton_block!
        @in_singleton_block = true
      end

      def exit_singleton_block!
        @in_singleton_block = false
      end
    end
  end
end
