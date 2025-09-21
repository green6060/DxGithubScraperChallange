# GitHub API Service - Handles all GitHub API interactions with robust error handling
class Github::GithubApiService < ApplicationService
  include HTTParty

  attribute :endpoint, :string
  attribute :params, default: -> { {} }
  attribute :headers, default: -> { {} }
  attribute :method, :string, default: 'GET'
  attribute :retry_count, :integer, default: 0

  def initialize(endpoint: '', params: {}, headers: {}, method: 'GET', retry_count: 0)
    super
    @endpoint = endpoint
    @params = params
    @headers = default_headers.merge(headers)
    @method = method.upcase
    @retry_count = retry_count
  end

  def call
    make_request_with_retry
  end

  private

  def make_request_with_retry
    begin
      make_request
    rescue Github::RateLimitError => e
      handle_rate_limit_error(e)
    rescue Github::ServerError => e
      handle_server_error(e)
    rescue Github::TransientError => e
      handle_transient_error(e)
    end
  end

  def make_request
    log_request_info
    
    response = case method
               when 'GET'
                 get_request
               when 'POST'
                 post_request
               when 'PUT'
                 put_request
               when 'PATCH'
                 patch_request
               when 'DELETE'
                 delete_request
               else
                 raise ArgumentError, "Unsupported HTTP method: #{method}"
               end

    log_response_info(response)
    handle_response(response)
  end

  def get_request
    HTTParty.get(full_url, request_options)
  end

  def post_request
    HTTParty.post(full_url, request_options)
  end

  def put_request
    HTTParty.put(full_url, request_options)
  end

  def patch_request
    HTTParty.patch(full_url, request_options)
  end

  def delete_request
    HTTParty.delete(full_url, request_options)
  end

  def request_options
    {
      headers: headers,
      query: method == 'GET' ? params : nil,
      body: method != 'GET' ? params.to_json : nil,
      timeout: config[:timeout],
      format: :json
    }.compact
  end

  def handle_response(response)
    case response.code
    when 200..299
      log_info "Request successful (#{response.code})"
      response.parsed_response
    when 401
      log_error "Authentication failed - check GitHub API token"
      raise Github::AuthenticationError, "GitHub API authentication failed"
    when 403
      handle_403_response(response)
    when 404
      log_error "Resource not found: #{full_url}"
      raise Github::NotFoundError, "GitHub API resource not found: #{endpoint}"
    when 422
      log_error "Validation failed"
      raise Github::ValidationError, "GitHub API validation failed: #{response.body}"
    when 429
      log_error "Rate limit exceeded"
      raise Github::RateLimitError, "GitHub API rate limit exceeded"
    when 500..599
      log_error "Server error: #{response.code}"
      raise Github::ServerError, "GitHub API server error: #{response.code}"
    when 502, 503, 504
      log_error "Service temporarily unavailable: #{response.code}"
      raise Github::TransientError, "GitHub API temporarily unavailable: #{response.code}"
    else
      log_error "Unexpected response code: #{response.code}"
      raise Github::ApiError, "GitHub API error: #{response.code} - #{response.body}"
    end
  end

  def handle_403_response(response)
    # Check if it's a rate limit or permissions issue
    if response.headers['x-ratelimit-remaining'] == '0'
      log_error "Rate limit exceeded (403 with 0 remaining)"
      raise Github::RateLimitError, "GitHub API rate limit exceeded"
    else
      log_error "Access forbidden - insufficient permissions"
      raise Github::ForbiddenError, "GitHub API access forbidden: #{response.body}"
    end
  end

  def handle_rate_limit_error(error)
    if retry_count < config[:rate_limit_max_retries]
      wait_time = calculate_backoff_delay(retry_count)
      log_info "Rate limit hit. Retrying in #{wait_time} seconds (attempt #{retry_count + 1}/#{config[:rate_limit_max_retries]})"
      
      sleep(wait_time)
      
      # Create new service instance with incremented retry count
      retry_service = Github::GithubApiService.new(
        endpoint: endpoint,
        params: params,
        headers: headers,
        method: method,
        retry_count: retry_count + 1
      )
      
      retry_service.call
    else
      log_error "Max retry attempts reached for rate limiting"
      raise error
    end
  end

  def handle_server_error(error)
    if retry_count < config[:rate_limit_max_retries]
      wait_time = calculate_backoff_delay(retry_count)
      log_info "Server error occurred. Retrying in #{wait_time} seconds (attempt #{retry_count + 1}/#{config[:rate_limit_max_retries]})"
      
      sleep(wait_time)
      
      retry_service = Github::GithubApiService.new(
        endpoint: endpoint,
        params: params,
        headers: headers,
        method: method,
        retry_count: retry_count + 1
      )
      
      retry_service.call
    else
      log_error "Max retry attempts reached for server errors"
      raise error
    end
  end

  def handle_transient_error(error)
    if retry_count < config[:rate_limit_max_retries]
      wait_time = calculate_backoff_delay(retry_count)
      log_info "Transient error occurred. Retrying in #{wait_time} seconds (attempt #{retry_count + 1}/#{config[:rate_limit_max_retries]})"
      
      sleep(wait_time)
      
      retry_service = Github::GithubApiService.new(
        endpoint: endpoint,
        params: params,
        headers: headers,
        method: method,
        retry_count: retry_count + 1
      )
      
      retry_service.call
    else
      log_error "Max retry attempts reached for transient errors"
      raise error
    end
  end

  def calculate_backoff_delay(attempt)
    # Exponential backoff with jitter
    base_delay = 2 ** attempt
    jitter = rand(0.1..0.5)
    [base_delay + jitter, 30].min # Cap at 30 seconds
  end

  def log_request_info
    log_debug "Making #{method} request to: #{full_url} (attempt #{retry_count + 1})"
    log_debug "Headers: #{headers.inspect}"
    log_debug "Params: #{params.inspect}" unless params.empty?
  end

  def log_response_info(response)
    log_debug "Response code: #{response.code}"
    log_debug "Response headers: #{response.headers.inspect}"
    log_debug "Response body length: #{response.body&.length || 0} characters"
    
    # Log rate limit info if available
    if response.headers['x-ratelimit-remaining']
      remaining = response.headers['x-ratelimit-remaining']
      limit = response.headers['x-ratelimit-limit']
      reset_time = Time.at(response.headers['x-ratelimit-reset'].to_i)
      
      log_info "Rate limit: #{remaining}/#{limit} remaining"
      log_info "Rate limit resets at: #{reset_time}"
      
      # Warning if approaching rate limit
      if remaining.to_i < 10
        log_error "⚠️ WARNING: Rate limit nearly exhausted (#{remaining} remaining)"
      end
    end
  end

  def default_headers
    {
      'Accept' => 'application/vnd.github.v3+json',
      'Authorization' => "token #{github_token}",
      'User-Agent' => 'DxGithubScraperChallenge/1.0',
      'Content-Type' => 'application/json'
    }
  end

  def github_token
    config[:token]
  end

  def base_url
    config[:base_url]
  end

  def full_url
    "#{base_url}/#{endpoint}".gsub(/\/+/, '/').gsub(/https?:\//, 'https://')
  end

  def config
    Rails.application.config.github_api
  end
end

# Custom error classes for GitHub API
class Github::AuthenticationError < StandardError; end
class Github::RateLimitError < StandardError; end
class Github::NotFoundError < StandardError; end
class Github::ValidationError < StandardError; end
class Github::ForbiddenError < StandardError; end
class Github::ServerError < StandardError; end
class Github::TransientError < StandardError; end
class Github::ApiError < StandardError; end
