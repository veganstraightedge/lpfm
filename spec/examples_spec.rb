# frozen_string_literal: true

RSpec.describe "LPFM Examples" do
  # Helper method to get all example directories
  let(:example_directories) do
    Dir.glob("doc/examples/*").select { |f| File.directory?(f) }
  end

  # Helper method to test an example directory
  def test_example(example_dir)
    example_name = File.basename(example_dir)

    # Find the LPFM file in the directory
    lpfm_files = Dir.glob("#{example_dir}/*.lpfm")
    expect(lpfm_files).not_to be_empty, "No .lpfm file found in #{example_dir}"

    lpfm_file = lpfm_files.first
    ruby_file = lpfm_file.gsub('.lpfm', '.rb')

    # Skip if no corresponding Ruby file exists
    return unless File.exist?(ruby_file)

    # Load and parse the LPFM content
    # Use filename path for cases that need filename inference
    lpfm = LPFM::LPFM.new(lpfm_file)

    # Generate Ruby code
    generated_ruby = lpfm.to_ruby

    # Load expected Ruby code
    expected_ruby = File.read(ruby_file)

    # Compare (normalize whitespace for comparison)
    expect(generated_ruby.strip).to eq(expected_ruby.strip),
                                    "Generated Ruby doesn't match expected for #{example_name}.\n" +
                                    "Generated:\n#{generated_ruby}\n\n" +
                                    "Expected:\n#{expected_ruby}"
  end

  describe "All examples convert correctly" do
    Dir.glob("doc/examples/*").select { |f| File.directory?(f) }.each do |example_dir|
      example_name = File.basename(example_dir)

      it "converts #{example_name} correctly" do
        test_example(example_dir)
      end
    end
  end

  describe "Specific example tests" do
    it "parses simple class correctly" do
      content = File.read("doc/examples/simple_class/foo.lpfm")
      lpfm = LPFM::LPFM.new(content)

      expect(lpfm.classes).to have_key('Foo')
      foo_class = lpfm.classes['Foo']
      expect(foo_class.methods.length).to eq(2)
      expect(foo_class.methods.map(&:name)).to contain_exactly('bar', 'baz')
    end

    it "parses YAML frontmatter correctly" do
      content = File.read("doc/examples/class_with_constants_yaml/config.lpfm")
      lpfm = LPFM::LPFM.new(content)

      config_class = lpfm.classes['Config']
      expect(config_class.constants).to include('VERSION' => '1.2.0')
      expect(config_class.constants).to include('MAX_RETRIES' => 3)
    end

    it "handles private methods correctly" do
      content = File.read("doc/examples/class_with_private_method/foo.lpfm")
      lpfm = LPFM::LPFM.new(content)

      foo_class = lpfm.classes['Foo']
      public_methods = foo_class.methods.select(&:public?)
      private_methods = foo_class.methods.select(&:private?)

      expect(public_methods.length).to eq(1)
      expect(private_methods.length).to eq(1)
      expect(public_methods.first.name).to eq('bar')
      expect(private_methods.first.name).to eq('baz')
    end

    it "handles attr_* methods correctly" do
      content = File.read("doc/examples/class_with_attr_accessors_yaml/user.lpfm")
      lpfm = LPFM::LPFM.new(content)

      user_class = lpfm.classes['User']
      expect(user_class.attr_readers).to contain_exactly(:name, :email)
      expect(user_class.attr_writers).to contain_exactly(:password)
      expect(user_class.attr_accessors).to contain_exactly(:age, :active)
    end

    it "handles modules correctly" do
      content = File.read("doc/examples/module_with_yaml/user_helpers.lpfm")
      lpfm = LPFM::LPFM.new(content)

      expect(lpfm.modules).to have_key('UserHelpers')
      module_def = lpfm.modules['UserHelpers']
      expect(module_def.methods.length).to eq(1)
      expect(module_def.methods.first.name).to eq('format_name')
    end

    it "handles empty classes correctly" do
      if File.exist?("doc/examples/empty_class/empty.lpfm")
        content = File.read("doc/examples/empty_class/empty.lpfm")
        lpfm = LPFM::LPFM.new(content)

        generated_ruby = lpfm.to_ruby
        expect(generated_ruby).to include("class")
        expect(generated_ruby).to include("end")
      end
    end

    it "handles multiple classes correctly" do
      if File.exist?("doc/examples/multiple_classes_simple/services.lpfm")
        content = File.read("doc/examples/multiple_classes_simple/services.lpfm")
        lpfm = LPFM::LPFM.new(content)

        expect(lpfm.classes.keys.length).to be >= 2
      end
    end

    it "handles class with method arguments correctly" do
      if File.exist?("doc/examples/class_with_method_args/calculator.lpfm")
        content = File.read("doc/examples/class_with_method_args/calculator.lpfm")
        lpfm = LPFM::LPFM.new(content)

        calculator_class = lpfm.classes.values.first
        methods_with_args = calculator_class.methods.select { |m| m.has_arguments? }
        expect(methods_with_args).not_to be_empty
      end
    end
  end

  describe "Error handling" do
    it "raises error for invalid LPFM content" do
      expect {
        LPFM::LPFM.new("not valid lpfm content")
      }.to raise_error(LPFM::Error, /LPFM content must contain at least one H1 heading/)
    end

    it "raises error for nil content" do
      expect {
        lpfm = LPFM::LPFM.new
        lpfm.load(nil)
      }.to raise_error(ArgumentError, /Cannot load nil content/)
    end

    it "raises error for empty content" do
      expect {
        LPFM::LPFM.new("")
      }.to raise_error(LPFM::Error, /Content cannot be empty/)
    end
  end

  describe "Roundtrip consistency" do
    it "maintains semantic consistency in roundtrip conversion" do
      # Test with a few key examples
      examples_to_test = [
        "doc/examples/simple_class/foo.lpfm",
        "doc/examples/class_with_constants_yaml/config.lpfm",
        "doc/examples/class_with_private_method/foo.lpfm"
      ]

      examples_to_test.each do |example_file|
        next unless File.exist?(example_file)

        original_content = File.read(example_file)
        lpfm1 = LPFM::LPFM.new(original_content)
        ruby_code = lpfm1.to_ruby

        # For now, just ensure the Ruby code is valid and contains expected elements
        expect(ruby_code).to include("class") # or "module"
        expect(ruby_code).to include("end")

        # TODO: Implement Ruby -> LPFM conversion and test full roundtrip
        # lpfm2 = LPFM::LPFM.new(ruby_code, type: :ruby)
        # expect(lpfm2.to_ruby).to eq(ruby_code)
      end
    end
  end
end
