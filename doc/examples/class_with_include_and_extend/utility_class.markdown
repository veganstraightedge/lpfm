```ruby
class UtilityClass
  include Comparable
  extend Forwardable

  def initialize(value)
    @value = value
  end

  def <=>(other)
    @value <=> other.value
  end

  def to_s
    @value.to_s
  end
end
```
