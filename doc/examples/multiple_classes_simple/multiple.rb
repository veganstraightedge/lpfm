class User
  def initialize(name)
    @name = name
  end

  def greet
    puts "Hello, #{@name}!"
  end
end

class Product
  def initialize(name, price)
    @name = name
    @price = price
  end

  def display
    puts "#{@name}: $#{@price}"
  end

  def on_sale?
    @price < 10.0
  end
end
