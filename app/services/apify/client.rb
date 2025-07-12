require 'net/http'
require 'json'
require 'singleton'

class Apify::Client
  include Singleton

  class ApifyError < StandardError; end
  class TimeoutError < ApifyError; end
  class RunFailedError < ApifyError; end

  DEFAULT_TIMEOUT = 300 # 5 minutes
  DEFAULT_POLL_INTERVAL = 5 # 5 seconds

  def initialize
    @api_token = ENV['APIFY_API_TOKEN']
    @base_url = 'https://api.apify.com/v2'
    @timeout = DEFAULT_TIMEOUT
    @poll_interval = DEFAULT_POLL_INTERVAL

    raise ApifyError, "API token is required" if @api_token.nil?
  end

  # Start an actor run
  def self.start_run(actor_id, input_data = {}, options = {})
    instance.start_run_instance(actor_id, input_data, options)
  end

  def start_run_instance(actor_id, input_data = {}, options = {})
    uri = URI("#{@base_url}/acts/#{actor_id}/runs?token=#{@api_token}")
    
    if options[:timeout_secs]
      uri.query = URI.encode_www_form(uri.query_values.to_h.merge(timeout: options[:timeout_secs]))
    end

    response = make_request(uri, :post) do |request|
      request['Content-Type'] = 'application/json'
      request.body = input_data.to_json
    end
    
    if response.code == '201'
      JSON.parse(response.body)
    else
      log_error("Failed to start actor run", response)
      nil
    end
  end

  def self.get_run_info(actor_id, run_id)
    instance.get_run_info(actor_id, run_id)
  end

  # Get run status and info
  def get_run_info(actor_id, run_id)
    uri = URI("#{@base_url}/acts/#{actor_id}/runs/#{run_id}?token=#{@api_token}")
    response = make_request(uri, :get)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      log_error("Failed to fetch run info", response)
      nil
    end
  end

  # Get just the run status
  def get_run_status(actor_id, run_id)
    run_info = get_run_info(actor_id, run_id)
    run_info&.dig('data', 'status')
  end

  # Wait for run completion
  def check_run_status(actor_id, run_id)
     get_run_status(actor_id, run_id)

     start_time = Time.current
    status.downcase
    loop do
      status = get_run_status(actor_id, run_id)
      
      case status
      when 'SUCCEEDED'
        return true
      when 'FAILED', 'ABORTED', 'TIMED-OUT'
        raise RunFailedError, "Actor run #{status.downcase}: #{run_id}"
      when nil
        raise RunFailedError, "Unable to get run status for: #{run_id}"
      end
      
      if Time.current - start_time > @timeout
        raise TimeoutError, "Actor run timed out after #{@timeout} seconds"
      end
      
      sleep @poll_interval
    end
  end

  def self.fetch_results(dataset_id, options = {})
    instance.fetch_results(dataset_id, options)
  end

  # Fetch results from completed run
  def fetch_results(dataset_id, options = {})
    query_params = { token: @api_token }
    
    # Add optional parameters
    query_params[:limit] = options[:limit] if options[:limit]
    query_params[:offset] = options[:offset] if options[:offset]
    query_params[:format] = options[:format] if options[:format]
    
    uri = URI("#{@base_url}/datasets/#{dataset_id}/items?token=#{@api_token}")

    uri.query = URI.encode_www_form(query_params)

    response = make_request(uri, :get)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      log_error("Failed to fetch results", response)
      []
    end
  end

  # Get actor details
  def get_actor_details(actor_id)
    uri = URI("#{@base_url}/acts/#{actor_id}?token=#{@api_token}")
    puts uri
    response = make_request(uri, :get)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      log_error("Failed to fetch actor details", response)
      nil
    end
  end

  # List all runs for an actor
  def list_runs(actor_id, options = {})
    query_params = { token: @api_token }
    
    # Add optional parameters
    query_params[:limit] = options[:limit] if options[:limit]
    query_params[:offset] = options[:offset] if options[:offset]
    query_params[:status] = options[:status] if options[:status]
    
    uri = URI("#{@base_url}/acts/#{actor_id}/runs")
    uri.query = URI.encode_www_form(query_params)
    
    response = make_request(uri, :get)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      log_error("Failed to list runs", response)
      { 'items' => [] }
    end
  end

  # Abort a running actor
  def abort_run(actor_id, run_id)
    uri = URI("#{@base_url}/acts/#{actor_id}/runs/#{run_id}/abort?token=#{@api_token}")
    
    response = make_request(uri, :post)
    
    response.code == '200'
  end

  private

  def make_request(uri, method = :get)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    request = case method
              when :get
                Net::HTTP::Get.new(uri)
              when :post
                Net::HTTP::Post.new(uri)
              when :put
                Net::HTTP::Put.new(uri)
              when :delete
                Net::HTTP::Delete.new(uri)
              else
                raise ArgumentError, "Unsupported HTTP method: #{method}"
              end
    
    yield(request) if block_given?
    
    http.request(request)
  rescue => e
    Rails.logger.error "HTTP request error: #{e.message}"
    raise ApifyError, "Request failed: #{e.message}"
  end

  def log_error(message, response)
    Rails.logger.error "#{message}: #{response.code} - #{response.body}"
  end
end 
