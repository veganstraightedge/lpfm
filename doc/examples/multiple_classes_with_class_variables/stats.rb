class StatCounter
  @@global_counter = 0
  @@count = 0

  def initialize
    @@count += 1
    @@global_counter += 1
  end

  def self.count
    @@count
  end

  def self.reset
    @@count = 0
  end
end

class AverageCounter
  @@global_counter = 0
  @@total = 0
  @@items = 0

  def add(value)
    @@total += value
    @@items += 1
    @@global_counter += 1
  end

  def average
    return 0 if @@items == 0
    @@total.to_f / @@items
  end

  def self.reset
    @@total = 0
    @@items = 0
  end
end
