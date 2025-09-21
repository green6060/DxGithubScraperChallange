class HomeController < ApplicationController
  def index
    @github_data = fetch_github_data
    @error_message = nil
  rescue => e
    @github_data = nil
    @error_message = e.message
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
