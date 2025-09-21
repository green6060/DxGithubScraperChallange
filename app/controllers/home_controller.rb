class HomeController < ApplicationController
  def index
    @github_data = fetch_github_data
    @error_message = nil
    @error_type = nil
  rescue Github::RateLimitError => e
    @github_data = nil
    @error_message = "Rate limit exceeded: #{e.message}"
    @error_type = 'rate_limit'
  rescue Github::AuthenticationError => e
    @github_data = nil
    @error_message = "Authentication failed: #{e.message}"
    @error_type = 'authentication'
  rescue Github::ServerError => e
    @github_data = nil
    @error_message = "GitHub API server error: #{e.message}"
    @error_type = 'server_error'
  rescue Github::TransientError => e
    @github_data = nil
    @error_message = "GitHub API temporarily unavailable: #{e.message}"
    @error_type = 'transient_error'
  rescue Github::NotFoundError => e
    @github_data = nil
    @error_message = "Resource not found: #{e.message}"
    @error_type = 'not_found'
  rescue => e
    @github_data = nil
    @error_message = "Unexpected error: #{e.message}"
    @error_type = 'unknown'
  end

  private

  def fetch_github_data
    # Fetch basic GitHub API data for display
    service = Github::GithubApiService.new(endpoint: 'rate_limit')
    rate_limit_data = service.call
    
    # Try to fetch a public repository as an example
    repo_service = Github::GithubApiService.new(endpoint: 'repos/vercel/next.js')
    repo_data = repo_service.call
    
    {
      rate_limit: rate_limit_data,
      sample_repository: repo_data,
      timestamp: Time.current
    }
  end
end
