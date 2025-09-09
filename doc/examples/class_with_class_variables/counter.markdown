```ruby
class Counter
  @@total_count = 0
  @@default_step = 1

  def initialize(initial_value = 0)
    @value = initial_value
    @@total_count += 1
  end

  def increment(step = @@default_step)
    @value += step
    @@total_count += step
  end

  def decrement(step = @@default_step)
    @value -= step
  end

  def value
    @value
  end

  def self.total_count
    @@total_count
  end

  def self.reset_total
    @@total_count = 0
  end

  def self.set_default_step(step)
    @@default_step = step
  end

  private

  def validate_step(step)
    raise ArgumentError, "Step must be positive" if step <= 0
  end

  def log_operation(operation, step)
    puts "#{operation}: #{step}, Total operations: #{@@total_count}"
  end
end
```
