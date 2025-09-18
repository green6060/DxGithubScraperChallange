# GitHub API Service - Base class for GitHub API interactions
class Github::GithubApiService < ApplicationService
  attribute :endpoint, :string
  attribute :params, default: -> { {} }
  attribute :headers, default: -> { {} }

  def initialize(endpoint: '', params: {}, headers: {})
    super
    @endpoint = endpoint
    @params = params
    @headers = default_headers.merge(headers)
  end

  def call
    make_request
  end

  private

  def make_request
    # This will be implemented in the next ticket
    raise NotImplementedError, "Request implementation will be added in Ticket 4"
  end

  def default_headers
    {
      'Accept' => 'application/vnd.github.v3+json',
      'Authorization' => "token #{github_token}",
      'User-Agent' => 'DxGithubScraperChallenge/1.0'
    }
  end

  def github_token
    Rails.application.config.github_api[:token]
  end

  def base_url
    Rails.application.config.github_api[:base_url]
  end

  def full_url
    "#{base_url}/#{endpoint}".gsub(/\/+/, '/').gsub(/https?:\//, 'https://')
  end
end
