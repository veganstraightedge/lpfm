# frozen_string_literal: true

require_relative "lib/lpfm/version"

Gem::Specification.new do |spec|
  spec.name = "lpfm"
  spec.version = Lpfm::VERSION
  spec.authors = ["Shane Becker"]
  spec.email = ["veganstraightedge@gmail.com"]

  spec.summary = "Literate Programming Flavored Markdown (LPFM)"
  spec.description = <<~DESCRIPTION.strip.gsub("\n", " ")
    Literate Programming Flavored Markdown (LPFM)
    is a file format, syntax for literate programming in Markdown,
    combining prose and code in the same file.
    Prose for humans and code for machines are both written in Markdown.
  DESCRIPTION
  spec.homepage = "https://github.com/veganstraightedge/lpfm"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.5"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/veganstraightedge/lpfm"
  spec.metadata["changelog_uri"] = "https://github.com/veganstraightedge/lpfm/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "kramdown", "~> 2.5"
end
