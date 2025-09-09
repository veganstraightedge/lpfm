# frozen_string_literal: true

require_relative "lpfm/version"

module LPFM
  class Error < StandardError; end

  # Core LPFM class for literate programming with Markdown
  class LPFM
    attr_reader :content, :type, :classes, :modules, :requires, :metadata

    def initialize(file_or_string = nil, type: :lpfm)
      @type = type
      @content = nil
      @classes = []
      @modules = []
      @requires = []
      @metadata = {}

      load(file_or_string) if file_or_string
    end

    def load(file_or_string)
      @content = case file_or_string
                 when String
                   file_or_string.start_with?('/') || File.exist?(file_or_string) ? File.read(file_or_string) : file_or_string
                 when File
                   file_or_string.read
                 else
                   raise ArgumentError, "Expected String or File, got #{file_or_string.class}"
                 end

      parse_content
      self
    end

    private

    def parse_content
      # TODO: Implement parsing logic based on @type
      # For now, just store the content
    end
  end
end
