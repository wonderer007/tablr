require 'net/http'
require 'json'
require 'uri'

class FindGoogleMapPlace
  URL = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json'

  def initialize(company_id:)
    @company = Marketing::Company.find(company_id)
  end

  def call
    uri = URI(URL)
    uri.query = URI.encode_www_form(
      input: input,
      inputtype: 'textquery',
      fields: 'place_id,name,formatted_address',
      key: ENV.fetch('GOOGLE_API_KEY')
    )

    response = http_get(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    place_id = data.dig('candidates', 0, 'place_id')

    place_id ? "https://www.google.com/maps/place/?q=place_id:#{place_id}" : nil
  rescue StandardError => e
    Rails.logger.error("FindGoogleMapPlace failed: #{e.class}: #{e.message}") if defined?(Rails)
    nil
  end

  def input
    @input ||= [company.name, company.address].compact.join(' ')
  end

  private

  attr_reader :company

  def http_get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request)
    end
  end
end
