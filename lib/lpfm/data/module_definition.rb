# frozen_string_literal: true

module LPFM
  module Data
    # Represents a Ruby module definition in LPFM
    class ModuleDefinition
      attr_accessor :name, :methods, :constants, :class_variables,
                    :attr_readers, :attr_writers, :attr_accessors, :includes, :extends,
                    :visibility_sections, :prose

      def initialize(name)
        @name = name
        @methods = []
        @constants = {}
        @class_variables = {}
        @attr_readers = []
        @attr_writers = []
        @attr_accessors = []
        @includes = []
        @extends = []
        @visibility_sections = { public: [], private: [], protected: [] }
        @prose = {}
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
        !@attr_readers.empty? || !@attr_writers.empty? || !@attr_accessors.empty?
      end

      def has_includes?
        !@includes.empty?
      end

      def has_extends?
        !@extends.empty?
      end
    end
  end
end
