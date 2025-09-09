require 'net/http'
require 'json'

class ApiService
  API_VERSION = "v1"

  def initialize(endpoint)
    @endpoint = endpoint
  end

  def fetch_data(path)
    validate_path(path)
    response = make_request(path)
    parse_response(response)
  end

  private

  def validate_path(path)
    raise "Invalid path" if path.nil? || path.empty?
  end

  def make_request(path)
    uri = URI("#{@endpoint}/#{API_VERSION}/#{path}")
    Net::HTTP.get_response(uri)
  end

  def parse_response(response)
    JSON.parse(response.body)
  end
end

class EmailService
  def initialize(smtp_server)
    @smtp_server = smtp_server
  end

  def send_email(to, subject, body)
    validate_email(to)
    compose_message(to, subject, body)
    deliver_message
  end

  private

  def validate_email(email)
    raise "Invalid email" unless email.include?('@')
  end

  def compose_message(to, subject, body)
    @message = "To: #{to}\nSubject: #{subject}\n\n#{body}"
  end

  def deliver_message
    puts "Sending via #{@smtp_server}: #{@message}"
  end
end
