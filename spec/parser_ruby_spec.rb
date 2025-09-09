# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe LPFM::Parser::Ruby do
  describe 'roundtrip conversion using doc/examples' do
    # Get all Ruby example files from doc/examples/
    example_files = Dir.glob('doc/examples/**/*.rb').map do |file|
      {
        path: file,
        name: File.basename(File.dirname(file)),
        ruby_file: file
      }
    end

    example_files.each do |example|
      context "#{example[:name]}" do
        let(:original_ruby_path) { example[:ruby_file] }
        let(:original_ruby_content) { File.read(original_ruby_path) }

        it 'maintains exact Ruby code through full roundtrip conversion' do
          # Step 1: Load original .rb file
          expect(File.exist?(original_ruby_path)).to be true
          expect(original_ruby_content.strip).not_to be_empty

          # Step 2: Convert Ruby to LPFM internal structure
          lpfm_from_ruby = LPFM::LPFM.new(original_ruby_content, type: :ruby)

          # Verify parsing succeeded
          total_definitions = lpfm_from_ruby.classes.size + lpfm_from_ruby.modules.size
          expect(total_definitions).to be > 0, "Expected to parse at least one class or module from #{original_ruby_path}"

          # Step 3: Convert LPFM internal structure to Ruby
          generated_ruby = lpfm_from_ruby.to_ruby

          # Step 4: Write generated Ruby to temporary file
          Tempfile.create(['test', '.rb']) do |ruby_tempfile|
            ruby_tempfile.write(generated_ruby)
            ruby_tempfile.rewind

            # Step 5: Load generated Ruby file and parse it again
            final_ruby_content = File.read(ruby_tempfile.path)
            lpfm_final = LPFM::LPFM.new(final_ruby_content, type: :ruby)

            # Step 6: Compare raw text content first
            original_normalized = normalize_ruby_code(original_ruby_content)
            generated_normalized = normalize_ruby_code(final_ruby_content)

            expect(generated_normalized).to eq(original_normalized),
                                            "Generated Ruby code should match original for #{example[:name]}.\n" +
                                            "Original:\n#{original_ruby_content}\n\n" +
                                            "Generated:\n#{final_ruby_content}\n\n" +
                                            "Difference in normalized versions"

            # Step 7: Compare original and final internal structures
            original_classes = lpfm_from_ruby.classes
            final_classes = lpfm_final.classes

            original_modules = lpfm_from_ruby.modules
            final_modules = lpfm_final.modules

            # Verify class consistency
            expect(final_classes.keys.sort).to eq(original_classes.keys.sort),
                                               "Class names should match after roundtrip for #{example[:name]}"

            original_classes.each do |class_name, original_class|
              final_class = final_classes[class_name]
              expect(final_class).not_to be_nil, "Class #{class_name} should exist after roundtrip"

              # Compare class properties
              expect(final_class.inherits_from).to eq(original_class.inherits_from),
                                                   "Inheritance should match for class #{class_name}"

              expect(final_class.includes.sort).to eq(original_class.includes.sort),
                                                   "Includes should match for class #{class_name}"

              expect(final_class.extends.sort).to eq(original_class.extends.sort),
                                                  "Extends should match for class #{class_name}"

              expect(final_class.attr_readers.sort).to eq(original_class.attr_readers.sort),
                                                       "Attr readers should match for class #{class_name}"

              expect(final_class.attr_writers.sort).to eq(original_class.attr_writers.sort),
                                                       "Attr writers should match for class #{class_name}"

              expect(final_class.attr_accessors.sort).to eq(original_class.attr_accessors.sort),
                                                         "Attr accessors should match for class #{class_name}"

              expect(final_class.constants).to eq(original_class.constants),
                                               "Constants should match for class #{class_name}"

              expect(final_class.class_variables).to eq(original_class.class_variables),
                                                     "Class variables should match for class #{class_name}"

              # Compare methods
              expect(final_class.methods.size).to eq(original_class.methods.size),
                                                  "Method count should match for class #{class_name}"

              original_methods = original_class.methods.sort_by(&:name)
              final_methods = final_class.methods.sort_by(&:name)

              original_methods.zip(final_methods).each do |orig_method, final_method|
                expect(final_method.name).to eq(orig_method.name),
                                             "Method name should match"

                expect(final_method.visibility).to eq(orig_method.visibility),
                                                   "Method visibility should match for #{orig_method.name}"

                expect(final_method.arguments).to eq(orig_method.arguments),
                                                  "Method arguments should match for #{orig_method.name}"

                expect(final_method.class_method?).to eq(orig_method.class_method?),
                                                      "Class method status should match for #{orig_method.name}"
              end
            end

            # Verify module consistency
            expect(final_modules.keys.sort).to eq(original_modules.keys.sort),
                                               "Module names should match after roundtrip for #{example[:name]}"

            original_modules.each do |module_name, original_module|
              final_module = final_modules[module_name]
              expect(final_module).not_to be_nil, "Module #{module_name} should exist after roundtrip"

              # Compare module properties (similar to classes)
              expect(final_module.includes.sort).to eq(original_module.includes.sort),
                                                    "Includes should match for module #{module_name}"

              expect(final_module.extends.sort).to eq(original_module.extends.sort),
                                                   "Extends should match for module #{module_name}"

              expect(final_module.constants).to eq(original_module.constants),
                                                "Constants should match for module #{module_name}"

              # Compare module methods
              original_methods = original_module.methods.sort_by(&:name)
              final_methods = final_module.methods.sort_by(&:name)

              expect(final_methods.size).to eq(original_methods.size),
                                            "Method count should match for module #{module_name}"

              original_methods.zip(final_methods).each do |orig_method, final_method|
                expect(final_method.name).to eq(orig_method.name),
                                             "Method name should match in module #{module_name}"

                expect(final_method.visibility).to eq(orig_method.visibility),
                                                   "Method visibility should match for #{module_name}.#{orig_method.name}"
              end
            end

            # Verify requires
            expect(lpfm_final.requires.sort).to eq(lpfm_from_ruby.requires.sort),
                                                "Requires should match after roundtrip"
          end
        end

        it 'parses Ruby file structure correctly' do
          lpfm = LPFM::LPFM.new(original_ruby_content, type: :ruby)

          # Basic structural validation
          total_definitions = lpfm.classes.size + lpfm.modules.size
          expect(total_definitions).to be > 0, "Should parse at least one class or module"

          # Validate all classes have valid structure
          lpfm.classes.each do |class_name, class_def|
            expect(class_name).to be_a(String)
            expect(class_name).not_to be_empty
            expect(class_def).to be_a(LPFM::Data::ClassDefinition)

            # Validate methods
            class_def.methods.each do |method|
              expect(method).to be_a(LPFM::Data::MethodDefinition)
              expect(method.name).to be_a(String)
              expect(method.name).not_to be_empty
              expect([:public, :private, :protected]).to include(method.visibility)
              expect(method.arguments).to be_an(Array)
            end
          end

          # Validate all modules have valid structure
          lpfm.modules.each do |module_name, module_def|
            expect(module_name).to be_a(String)
            expect(module_name).not_to be_empty
            expect(module_def).to be_a(LPFM::Data::ModuleDefinition)

            # Validate methods
            module_def.methods.each do |method|
              expect(method).to be_a(LPFM::Data::MethodDefinition)
              expect(method.name).to be_a(String)
              expect(method.name).not_to be_empty
              expect([:public, :private, :protected]).to include(method.visibility)
            end
          end
        end
      end
    end
  end

  describe 'specific parsing features' do
    context 'when parsing mixed visibility example' do
      let(:mixed_visibility_file) { 'doc/examples/mixed_visibility/service.rb' }
      let(:ruby_content) { File.read(mixed_visibility_file) }

      it 'correctly parses method visibility order' do
        lpfm = LPFM::LPFM.new(ruby_content, type: :ruby)
        service_class = lpfm.classes['Service']

        methods_with_visibility = service_class.methods.map { |m| [m.name, m.visibility] }

        expect(methods_with_visibility).to include(
          ['initialize', :public],
          ['public_method', :public],
          ['private_helper', :private],
          ['protected_method', :protected],
          ['another_public_method', :public],
          ['another_private_method', :private]
        )
      end
    end

    context 'when parsing class with attributes' do
      let(:attr_file) { Dir.glob('doc/examples/**/class_with_attr*/*.rb').first }

      it 'correctly parses attr_* declarations' do
        skip "No attr examples found" unless attr_file

        ruby_content = File.read(attr_file)
        lpfm = LPFM::LPFM.new(ruby_content, type: :ruby)

        # Should have at least one class with attributes
        class_with_attrs = lpfm.classes.values.find do |c|
          c.has_attr_methods?
        end

        expect(class_with_attrs).not_to be_nil, "Should find a class with attributes"
      end
    end

    context 'when parsing class with constants' do
      let(:constant_files) { Dir.glob('doc/examples/**/class_with_constants*/*.rb') }

      it 'correctly parses constant definitions' do
        skip "No constant examples found" if constant_files.empty?

        constant_files.each do |file|
          ruby_content = File.read(file)
          lpfm = LPFM::LPFM.new(ruby_content, type: :ruby)

          # Should have at least one class with constants
          class_with_constants = lpfm.classes.values.find { |c| c.constants.any? }
          expect(class_with_constants).not_to be_nil, "Should find a class with constants in #{file}"
        end
      end
    end

  end

  private

  def normalize_ruby_code(code)
    # Normalize Ruby code for comparison by:
    # 1. Removing trailing whitespace from each line
    # 2. Removing empty lines at the beginning and end
    # 3. Ensuring consistent indentation
    # 4. Normalizing line endings

    lines = code.split(/\r?\n/)

    # Remove trailing whitespace from each line
    lines = lines.map(&:rstrip)

    # Remove empty lines from beginning and end
    lines = lines.drop_while(&:empty?).reverse.drop_while(&:empty?).reverse

    # Join back with consistent line endings
    lines.join("\n")
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
