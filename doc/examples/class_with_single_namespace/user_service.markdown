```ruby
module MyApp
  class UserService
    def initialize(database)
      @database = database
    end

    def self.connection_status
      "Connected to #{@database_url}"
    end
  end
end
```
