class SplatService
  def array_splat(*items)
    items.each { |item| puts "Processing: #{item}" }
    return items.size
  end

  def hash_splat(**options)
    options.each do |key, value|
      puts "#{key}: #{value}"
    end
  end

  def block_splat(&block)
    puts "Received block: #{block_given?}"
    yield("result") if block_given?
  end

  def mixed_splat(required, optional = "default", *args, keyword:, **kwargs, &block)
    puts "Required: #{required}"
    puts "Optional: #{optional}"
    puts "Args: #{args.inspect}"
    puts "Keyword: #{keyword}"
    puts "Kwargs: #{kwargs.inspect}"

    result = yield(required, keyword) if block_given?
    [required, optional, args, keyword, kwargs, result]
  end

  def self.class_splat(*values, **settings)
    instance = new
    instance.array_splat(*values)
    instance.hash_splat(**settings)
  end

  private

  def helper_splat(*data, prefix: "[LOG]", **meta)
    timestamp = Time.now
    data.each do |item|
      puts "#{prefix} #{timestamp}: #{item}"
    end

    meta.each do |k, v|
      puts "Meta #{k}: #{v}"
    end
  end

  def process_all(*items, &transformer)
    items.map do |item|
      transformer ? transformer.call(item) : item.to_s
    end
  end
end
