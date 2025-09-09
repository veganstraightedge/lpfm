require 'json'
require 'logger'

module Utils
  class DataProcessor
    include Enumerable

    VERSION = "2.0.0"

    attr_reader :logger
    attr_accessor :debug_mode

    def initialize(*datasets, **config)
      @datasets = datasets.flatten
      @config = config
      @debug_mode = config.fetch(:debug, false)
    end

    def process(*items, format: :json, **options)
      validate_input(items, format, options)

      items.map do |item|
        process_single_item(item, format)
      end
    end

    def merge(*other_processors, **merge_options)
      merged_data = []

      other_processors.each do |processor|
        merged_data.concat(processor.datasets)
      end

      self.class.new(*merged_data, **merge_options)
    end

    def self.bulk_create(*datasets, **config)
      processors = []

      datasets.each do |dataset|
        processor = new(dataset, **config)
        processors.push(processor)
      end

      processors
    end

    private

    def validate_input(items, format, options)
      raise ArgumentError, "Items cannot be empty" if items.empty?
      raise ArgumentError, "Invalid format" unless [:json, :xml].include?(format)
    end

    def process_single_item(item, format)
      case format
      when :json
        item.to_json
      when :xml
        item.to_xml
      else
        item.to_s
      end
    end

    def datasets
      @datasets
    end
  end
end
