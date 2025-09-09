module API
  module V1
    class Client
      def initialize(api_key:, base_url: 'https://api.example.com')
        @api_key = api_key
        @base_url = base_url
        @headers = {
          'Authorization' => "Bearer #{api_key}",
          'Content-Type' => 'application/json'
        }
      end

      def get(endpoint, params: {})
        uri = build_uri(endpoint, params)
        make_request(:get, uri)
      end

      def post(endpoint, data:, headers: {})
        uri = build_uri(endpoint)
        merged_headers = @headers.merge(headers)

        make_request(:post, uri, data, merged_headers)
      end

      def self.version
        "v1.2.0"
      end

      private

      def build_uri(endpoint, params = {})
        uri = URI("#{@base_url}/#{endpoint}")
        uri.query = URI.encode_www_form(params) if params.any?
        uri
      end

      def make_request(method, uri, data = nil, headers = @headers)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request = case method
        when :get
          Net::HTTP::Get.new(uri)
        when :post
          req = Net::HTTP::Post.new(uri)
          req.body = data.to_json if data
          req
        end

        headers.each { |key, value| request[key] = value }
        response = http.request(request)
        JSON.parse(response.body)
      end
    end
  end
end
