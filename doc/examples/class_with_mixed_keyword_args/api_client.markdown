```ruby
class ApiClient
  def initialize(base_url, timeout = 30, retries: 3, debug: false)
    @base_url = base_url
    @timeout = timeout
    @retries = retries
    @debug = debug
  end

  def fetch(endpoint, params = {}, headers: {}, method: :get)
    uri = URI("#{@base_url}/#{endpoint}")
    uri.query = URI.encode_www_form(params) if params.any?

    request = build_request(method, uri, headers)
    perform_request(request)
  end
end
```
