# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LPFM::Parser::Ruby do
  describe '#parse' do
    context 'simple class' do
      let(:ruby_code) do
        <<~RUBY
          class SimpleClass
            def method_one
              puts "Hello"
            end

            def method_two
              puts "World"
            end
          end
        RUBY
      end

      it 'parses class and methods correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        expect(lpfm.classes.keys).to eq(['SimpleClass'])

        class_def = lpfm.classes['SimpleClass']
        expect(class_def.methods.map(&:name)).to eq(['method_one', 'method_two'])
        expect(class_def.methods.all?(&:public?)).to be true
      end
    end

    context 'class with inheritance' do
      let(:ruby_code) do
        <<~RUBY
          class CustomError < StandardError
            def message
              "Custom error occurred"
            end
          end
        RUBY
      end

      it 'parses inheritance correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        class_def = lpfm.classes['CustomError']
        expect(class_def.inherits_from).to eq('StandardError')
      end
    end

    context 'class with visibility modifiers' do
      let(:ruby_code) do
        <<~RUBY
          class VisibilityExample
            def public_method
              puts "Public"
            end

            private

            def private_method
              puts "Private"
            end

            protected

            def protected_method
              puts "Protected"
            end
          end
        RUBY
      end

      it 'parses method visibility correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        class_def = lpfm.classes['VisibilityExample']
        methods = class_def.methods

        public_method = methods.find { |m| m.name == 'public_method' }
        private_method = methods.find { |m| m.name == 'private_method' }
        protected_method = methods.find { |m| m.name == 'protected_method' }

        expect(public_method.visibility).to eq(:public)
        expect(private_method.visibility).to eq(:private)
        expect(protected_method.visibility).to eq(:protected)
      end
    end

    context 'class with attr_* methods' do
      let(:ruby_code) do
        <<~RUBY
          class AttrExample
            attr_reader :name, :age
            attr_writer :email
            attr_accessor :status
          end
        RUBY
      end

      it 'parses attr_* declarations correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        class_def = lpfm.classes['AttrExample']
        expect(class_def.attr_readers).to include(:name, :age)
        expect(class_def.attr_writers).to include(:email)
        expect(class_def.attr_accessors).to include(:status)
      end
    end

    context 'class with constants' do
      let(:ruby_code) do
        <<~RUBY
          class ConstantExample
            VERSION = "1.0.0"
            MAX_SIZE = 100
            ENABLED = true

            def get_version
              VERSION
            end
          end
        RUBY
      end

      it 'parses constants correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        class_def = lpfm.classes['ConstantExample']
        expect(class_def.constants).to include(
          'VERSION' => '1.0.0',
          'MAX_SIZE' => 100,
          'ENABLED' => true
        )
      end
    end

    context 'class with include and extend' do
      let(:ruby_code) do
        <<~RUBY
          class MixinExample
            include Enumerable
            extend Forwardable

            def initialize
              @items = []
            end
          end
        RUBY
      end

      it 'parses include and extend correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        class_def = lpfm.classes['MixinExample']
        expect(class_def.includes).to include('Enumerable')
        expect(class_def.extends).to include('Forwardable')
      end
    end

    context 'class with method arguments' do
      let(:ruby_code) do
        <<~RUBY
          class ArgumentExample
            def simple_args(a, b)
              a + b
            end

            def default_args(x, y = 10)
              x + y
            end

            def splat_args(*args)
              args.sum
            end

            def keyword_args(user_name:, age: 25)
              "\#{user_name} is \#{age}"
            end

            def all_args(req, opt = 'default', *splat, key:, key_opt: 'default', **kwargs, &block)
              # Complex method signature
            end
          end
        RUBY
      end

      it 'parses method arguments correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        class_def = lpfm.classes['ArgumentExample']
        methods = class_def.methods

        simple_method = methods.find { |m| m.name == 'simple_args' }
        expect(simple_method.arguments).to eq(['a', 'b'])

        default_method = methods.find { |m| m.name == 'default_args' }
        expect(default_method.arguments).to include('x')
        expect(default_method.arguments.any? { |arg| arg.include?('y = 10') }).to be true

        splat_method = methods.find { |m| m.name == 'splat_args' }
        expect(splat_method.arguments.any? { |arg| arg.start_with?('*args') }).to be true

        keyword_method = methods.find { |m| m.name == 'keyword_args' }
        expect(keyword_method.arguments.any? { |arg| arg.include?('user_name:') }).to be true
        expect(keyword_method.arguments.any? { |arg| arg.include?('age: 25') }).to be true
      end
    end

    context 'module' do
      let(:ruby_code) do
        <<~RUBY
          module HelperModule
            def helper_method
              "I'm helping!"
            end

            private

            def private_helper
              "Private help"
            end
          end
        RUBY
      end

      it 'parses modules correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        expect(lpfm.modules.keys).to eq(['HelperModule'])

        module_def = lpfm.modules['HelperModule']
        methods = module_def.methods

        expect(methods.map(&:name)).to include('helper_method', 'private_helper')

        helper_method = methods.find { |m| m.name == 'helper_method' }
        private_method = methods.find { |m| m.name == 'private_helper' }

        expect(helper_method.visibility).to eq(:public)
        expect(private_method.visibility).to eq(:private)
      end
    end

    context 'class with class variables' do
      let(:ruby_code) do
        <<~RUBY
          class ClassVarExample
            @@count = 0
            @@name = "Example"

            def initialize
              @@count += 1
            end
          end
        RUBY
      end

      it 'parses class variables correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        class_def = lpfm.classes['ClassVarExample']
        expect(class_def.class_variables).to include(
          '@@count' => 0,
          '@@name' => 'Example'
        )
      end
    end

    context 'multiple classes' do
      let(:ruby_code) do
        <<~RUBY
          class FirstClass
            def first_method
              "first"
            end
          end

          class SecondClass
            def second_method
              "second"
            end
          end
        RUBY
      end

      it 'parses multiple classes correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        expect(lpfm.classes.keys).to match_array(['FirstClass', 'SecondClass'])

        first_class = lpfm.classes['FirstClass']
        second_class = lpfm.classes['SecondClass']

        expect(first_class.methods.map(&:name)).to eq(['first_method'])
        expect(second_class.methods.map(&:name)).to eq(['second_method'])
      end
    end

    context 'require statements' do
      let(:ruby_code) do
        <<~RUBY
          require 'json'
          require 'yaml'
          require_relative 'helper'

          class RequireExample
            def parse_json(data)
              JSON.parse(data)
            end
          end
        RUBY
      end

      it 'parses require statements correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        expect(lpfm.requires).to include('json', 'yaml')
        # Note: require_relative is handled differently in some Ruby parsers
      end
    end

    context 'empty class' do
      let(:ruby_code) do
        <<~RUBY
          class EmptyClass
          end
        RUBY
      end

      it 'parses empty class correctly' do
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        expect(lpfm.classes.keys).to eq(['EmptyClass'])

        class_def = lpfm.classes['EmptyClass']
        expect(class_def.methods).to be_empty
        expect(class_def.constants).to be_empty
        expect(class_def.attr_readers).to be_empty
      end
    end

    context 'roundtrip conversion' do
      let(:ruby_code) do
        <<~RUBY
          class RoundtripTest
            include Comparable
            attr_reader :value

            VERSION = "1.0"

            def initialize(value)
              @value = value
            end

            def compare_with(other)
              value <=> other.value
            end

            private

            def helper
              "helping"
            end
          end
        RUBY
      end

      it 'maintains consistency in roundtrip conversion' do
        # Parse Ruby → LPFM internal structure
        lpfm = LPFM::LPFM.new(ruby_code, type: :ruby)

        # Convert back to Ruby
        generated_ruby = lpfm.to_ruby

        # Parse the generated Ruby again
        lpfm_roundtrip = LPFM::LPFM.new(generated_ruby, type: :ruby)

        # Compare the two internal structures
        original_class = lpfm.classes['RoundtripTest']
        roundtrip_class = lpfm_roundtrip.classes['RoundtripTest']

        expect(roundtrip_class.includes).to eq(original_class.includes)
        expect(roundtrip_class.attr_readers).to eq(original_class.attr_readers)
        expect(roundtrip_class.constants).to eq(original_class.constants)
        expect(roundtrip_class.methods.map(&:name)).to eq(original_class.methods.map(&:name))
        expect(roundtrip_class.methods.map(&:visibility)).to eq(original_class.methods.map(&:visibility))
      end
    end
  end

  describe 'error handling' do
    it 'raises error for invalid Ruby syntax' do
      invalid_ruby = "class Foo def bar"

      expect {
        LPFM::LPFM.new(invalid_ruby, type: :ruby)
      }.to raise_error(LPFM::Error, /Invalid Ruby syntax|Failed to parse Ruby code/)
    end

    it 'raises error for empty content' do
      expect {
        LPFM::LPFM.new("", type: :ruby)
      }.to raise_error(LPFM::Error, /cannot be empty/)
    end

    it 'creates empty LPFM object for nil content' do
      lpfm = LPFM::LPFM.new(nil, type: :ruby)
      expect(lpfm.classes).to be_empty
      expect(lpfm.modules).to be_empty
    end
  end
end
