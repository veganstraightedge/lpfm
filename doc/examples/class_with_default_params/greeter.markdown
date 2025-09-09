```ruby
class Greeter
  def greet(name = "World")
    puts "Hello, #{name}!"
  end

  def farewell(name = "friend", punctuation = ".")
    puts "Goodbye, #{name}#{punctuation}"
  end

  def welcome(message, times = 1)
    times.times { puts message }
  end
end
```
