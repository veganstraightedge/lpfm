```ruby
class Service
  def initialize
    @data = {}
  end

  def public_method
    puts "This is public"
    private_helper
  end

  private

  def private_helper
    puts "This is private"
  end

  protected

  def protected_method
    puts "This is protected"
  end

  public

  def another_public_method
    puts "Another public method"
    protected_method
  end

  private

  def another_private_method
    puts "Another private method"
  end
end
```
