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
    
    # Get collected repository data from database
    repository_stats = get_repository_stats
    recent_repositories = get_recent_repositories
    popular_repositories = get_popular_repositories
    
    {
      rate_limit: rate_limit_data,
      repository_stats: repository_stats,
      recent_repositories: recent_repositories,
      popular_repositories: popular_repositories,
      timestamp: Time.current
    }
  end

  def get_repository_stats
    {
      total_count: Repository.count,
      public_count: Repository.public_repos.count,
      private_count: Repository.private_repos.count,
      active_count: Repository.active.count,
      archived_count: Repository.archived.count,
      last_updated: Repository.maximum(:updated_at)
    }
  end

  def get_recent_repositories
    Repository.order(created_at: :desc).limit(10)
  end

  def get_popular_repositories
    # For now, just get some sample repositories
    # In a real app, we'd sort by stars or activity
    Repository.limit(10)
  end
end
