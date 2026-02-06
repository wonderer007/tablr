module Marketing
  class EmailVerifier
    RESULT_MAPPING = {
      "valid" => "valid",
      "invalid" => "invalid",
      "disposable" => "disposable",
      "catchall" => "accept_all",
      "unknown" => "unknown"
    }.freeze

    def initialize(email)
      @email = email
    end

    def call
      return default_response if Rails.env.development?

      client = NeverBounce::API::Client.new(api_key: ENV["NEVER_BOUNCE_API_KEY"])
      response = client.single_check(email: @email)

      if response.ok?
        {
          email_status: map_result(response.result),
          never_bounce_response: {
            result: response.result,
            flags: response.flags,
            checked_at: Time.current.iso8601
          }
        }
      else
        { error: "#{response.status}: #{response.message}" }
      end
    rescue StandardError => e
      { error: e.message }
    end

    private

    def map_result(result)
      RESULT_MAPPING[result] || "unknown"
    end

    def default_response
      { 
        email_status: "valid",
        never_bounce_response: {
          result: "valid",
          flags: {},
          checked_at: Time.current.iso8601
        }
      }
    end
  end
end
