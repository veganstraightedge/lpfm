```ruby
require 'json'
require 'net/http'

class ApiClient
  def fetch_user
    response = Net::HTTP.get_response(URI('https://api.example.com/user'))
    JSON.parse(response.body)
  end
end
```
