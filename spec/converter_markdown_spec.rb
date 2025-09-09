# frozen_string_literal: true

RSpec.describe "LPFM Markdown Converter Examples" do
  # Helper method to get all example directories
  let(:example_directories) do
    Dir.glob("doc/examples/*").select { |f| File.directory?(f) }
  end

  # Helper method to test an example directory
  def test_markdown_example(example_dir)
    example_name = File.basename(example_dir)

    # Find the LPFM file in the directory
    lpfm_files = Dir.glob("#{example_dir}/*.lpfm")
    expect(lpfm_files).not_to be_empty, "No .lpfm file found in #{example_dir}"

    lpfm_file = lpfm_files.first
    markdown_file = lpfm_file.gsub('.lpfm', '.markdown')

    # Skip if no corresponding Markdown file exists
    return unless File.exist?(markdown_file)

    # Load and parse the LPFM content
    # Use filename path for cases that need filename inference
    lpfm = LPFM::LPFM.new(lpfm_file)

    # Generate Markdown code
    generated_markdown = lpfm.to_markdown

    # Load expected Markdown code
    expected_markdown = File.read(markdown_file)

    # Compare (normalize whitespace for comparison)
    expect(generated_markdown.strip).to eq(expected_markdown.strip),
      "Generated Markdown doesn't match expected for #{example_name}.\n" +
      "Generated:\n#{generated_markdown}\n\n" +
      "Expected:\n#{expected_markdown}"
  end

  describe "All examples convert correctly to Markdown" do
    Dir.glob("doc/examples/*").select { |f| File.directory?(f) }.each do |example_dir|
      example_name = File.basename(example_dir)

      it "converts #{example_name} to markdown correctly" do
        test_markdown_example(example_dir)
      end
    end
  end

  describe "Markdown converter methods" do
    it "to_markdown generates fenced Ruby code blocks" do
      content = File.read("doc/examples/simple_class/foo.lpfm")
      lpfm = LPFM::LPFM.new(content)
      markdown = lpfm.to_markdown

      expect(markdown).to include("```ruby")
      expect(markdown).to include("```")
      expect(markdown).to include("class Foo")
      expect(markdown).to include("def bar")
    end

    it "to_md is an alias for to_markdown" do
      content = File.read("doc/examples/simple_class/foo.lpfm")
      lpfm = LPFM::LPFM.new(content)

      expect(lpfm.to_md).to eq(lpfm.to_markdown)
    end
  end

  describe "Error handling" do
    it "raises error for invalid LPFM content" do
      expect {
        LPFM::LPFM.new("not valid lpfm content").to_markdown
      }.to raise_error(LPFM::Error, /LPFM content must contain at least one H1 heading/)
    end

    it "returns empty string for LPFM object with no content" do
      lpfm = LPFM::LPFM.new("# EmptyClass")
      markdown = lpfm.to_markdown

      expect(markdown).to include("```ruby")
      expect(markdown).to include("class EmptyClass")
      expect(markdown).to include("end")
      expect(markdown).to include("```")
    end
  end
end
