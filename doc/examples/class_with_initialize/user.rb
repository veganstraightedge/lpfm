class User
  def initialize(name, email)
    @name = name
    @email = email
  end

  def greet
    puts "Hello, #{@name}!"
  end
end
