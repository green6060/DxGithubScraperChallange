# GitHub API Configuration
Rails.application.configure do
  config.github_api = {
    base_url: ENV.fetch('GITHUB_API_BASE_URL', 'https://api.github.com'),
    token: ENV.fetch('GITHUB_API_TOKEN', ''),
    rate_limit_requests_per_hour: ENV.fetch('GITHUB_RATE_LIMIT_REQUESTS_PER_HOUR', '5000').to_i,
    rate_limit_backoff_multiplier: ENV.fetch('GITHUB_RATE_LIMIT_BACKOFF_MULTIPLIER', '2').to_f,
    rate_limit_max_retries: ENV.fetch('GITHUB_RATE_LIMIT_MAX_RETRIES', '3').to_i,
    timeout: ENV.fetch('GITHUB_API_TIMEOUT', '30').to_i
  }
end
