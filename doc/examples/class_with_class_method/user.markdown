```ruby
class User
  def initialize(name)
    @name = name
  end

  def greet
    puts "Hello, #{@name}!"
  end

  def self.all
    puts "Getting all users..."
  end
end
```
