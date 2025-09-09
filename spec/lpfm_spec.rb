# frozen_string_literal: true

RSpec.describe LPFM do
  it "has a version number" do
    expect(LPFM::VERSION).not_to be nil
  end

  describe "LPFM class" do
    it "can be instantiated without arguments" do
      lpfm = LPFM::LPFM.new
      expect(lpfm).to be_a(LPFM::LPFM)
    end

    it "can parse simple LPFM content" do
      content = "# Foo\n\n## bar\nputs 'hello'"
      lpfm = LPFM::LPFM.new(content)

      expect(lpfm.classes).to have_key('Foo')
      foo_class = lpfm.classes['Foo']
      expect(foo_class.methods.length).to eq(1)
      expect(foo_class.methods.first.name).to eq('bar')
      expect(foo_class.methods.first.body).to eq("puts 'hello'")
    end

    it "can convert to Ruby code" do
      content = "# Foo\n\n## bar\nputs 'hello'"
      lpfm = LPFM::LPFM.new(content)
      ruby_code = lpfm.to_ruby

      expect(ruby_code).to include("class Foo")
      expect(ruby_code).to include("def bar")
      expect(ruby_code).to include("puts 'hello'")
      expect(ruby_code).to include("end")
    end
  end
end
