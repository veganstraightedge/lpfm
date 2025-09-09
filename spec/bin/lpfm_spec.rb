require "open3"
require "fileutils"

# binding.irb

CLI_PATH     = File.expand_path("../../bin/lpfm", __dir__)
FIXTURES_DIR = File.expand_path("../../fixtures", __dir__)

RSpec.describe "lpfm CLI" do
  before(:each) do
    FileUtils.mkdir_p(FIXTURES_DIR)
    File.write("#{FIXTURES_DIR}/hello.lpfm", "# HelloWorld\n## greet\nHello from LPFM!")
    File.write("#{FIXTURES_DIR}/hello.rb", <<~RUBY)
      class HelloWorld
        def greet
          # Hello from LPFM!
        end
      end
    RUBY
  end

  after(:each) do
    FileUtils.rm_f("#{FIXTURES_DIR}/out.rb")
    FileUtils.rm_f("#{FIXTURES_DIR}/out.lpfm")
    FileUtils.rm_f("#{FIXTURES_DIR}/hello.lpfm")
    FileUtils.rm_f("#{FIXTURES_DIR}/hello.rb")
  end

  it "shows help with --help" do
    stdout, stderr, status = Open3.capture3("#{CLI_PATH} --help")
    expect(status.success?).to be true
    expect(stdout).to include("Usage: lpfm")
  end

  it "converts LPFM to Ruby" do
    stdout, stderr, status = Open3.capture3("#{CLI_PATH} -i #{FIXTURES_DIR}/hello.lpfm -o #{FIXTURES_DIR}/out.rb")
    expect(status.success?).to be true
    expect(File.read("#{FIXTURES_DIR}/out.rb")).to include("class HelloWorld")
  end

  # it "converts Ruby to LPFM" do
  #   stdout, stderr, status = Open3.capture3("#{CLI_PATH} -i #{FIXTURES_DIR}/hello.rb -o #{FIXTURES_DIR}/out.lpfm")
  #   expect(status.success?).to be true
  #   expect(File.read("#{FIXTURES_DIR}/out.lpfm")).to include("# HelloWorld")
  # end

  it "reads from stdin and writes to stdout" do
    input = "# HelloWorld\n## greet\nHello from LPFM!"
    stdout, stderr, status = Open3.capture3("#{CLI_PATH} --input-format lpfm --output-format rb", stdin_data: input)
    expect(status.success?).to be true
    expect(stdout).to include("class HelloWorld")
  end

  it "fails gracefully on unknown format" do
    stdout, stderr, status = Open3.capture3("#{CLI_PATH} --input-format foo", stdin_data: "irrelevant")
    expect(status.success?).to be false
    expect(stderr + stdout).to match(/Unknown input format/i)
  end
end
