# GitHub API Service - Handles all GitHub API interactions
class Github::GithubApiService < ApplicationService
  include HTTParty

  attribute :endpoint, :string
  attribute :params, default: -> { {} }
  attribute :headers, default: -> { {} }
  attribute :method, :string, default: 'GET'

  def initialize(endpoint: '', params: {}, headers: {}, method: 'GET')
    super
    @endpoint = endpoint
    @params = params
    @headers = default_headers.merge(headers)
    @method = method.upcase
  end

  def call
    make_request
  end

  private

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
      log_error "Rate limit exceeded or forbidden"
      raise Github::RateLimitError, "GitHub API rate limit exceeded or access forbidden"
    when 404
      log_error "Resource not found"
      raise Github::NotFoundError, "GitHub API resource not found"
    when 422
      log_error "Validation failed"
      raise Github::ValidationError, "GitHub API validation failed: #{response.body}"
    else
      log_error "Unexpected response code: #{response.code}"
      raise Github::ApiError, "GitHub API error: #{response.code} - #{response.body}"
    end
  end

  def log_request_info
    log_debug "Making #{method} request to: #{full_url}"
    log_debug "Headers: #{headers.inspect}"
    log_debug "Params: #{params.inspect}" unless params.empty?
  end

  def log_response_info(response)
    log_debug "Response code: #{response.code}"
    log_debug "Response headers: #{response.headers.inspect}"
    log_debug "Response body length: #{response.body&.length || 0} characters"
    
    # Log rate limit info if available
    if response.headers['x-ratelimit-remaining']
      log_info "Rate limit remaining: #{response.headers['x-ratelimit-remaining']}"
      log_info "Rate limit reset: #{Time.at(response.headers['x-ratelimit-reset'].to_i)}"
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
class Github::ApiError < StandardError; end
