class EventManager
  def initialize(name)
    @name = name
    @callbacks = []
  end

  def on_event(&block)
    @callbacks << block if block_given?
  end

  def process_items(items, &processor)
    return [] unless block_given?
    items.map(&processor)
  end

  def with_timing(operation_name, &block)
    start_time = Time.now
    result = yield if block_given?
    end_time = Time.now
    puts "#{operation_name} took #{end_time - start_time} seconds"
    result
  end

  def batch_process(data, batch_size = 10, &block)
    return [] unless block_given?
    data.each_slice(batch_size) do |batch|
      yield(batch)
    end
  end

  def self.configure(&block)
    yield(self) if block_given?
  end

  private

  def validate_block(&block)
    raise ArgumentError, "Block required" unless block_given?
    block
  end

  def execute_with_rescue(&block)
    begin
      yield if block_given?
    rescue StandardError => e
      puts "Error: #{e.message}"
      nil
    end
  end
end
