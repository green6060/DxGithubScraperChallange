# GitHub Repository Data Collection Service
class Github::RepositoryService < ApplicationService
  attribute :organization, :string, default: 'vercel'
  attribute :page, :integer, default: 1
  attribute :per_page, :integer, default: 100
  attribute :include_private, :boolean, default: false

  def initialize(organization: 'vercel', page: 1, per_page: 100, include_private: false)
    super
    @organization = organization
    @page = page
    @per_page = [per_page, 100].min # GitHub API max is 100 per page
    @include_private = include_private
  end

  def call
    fetch_organization_repositories
  end

  private

  def fetch_organization_repositories
    log_info "Fetching repositories for organization: #{organization} (page #{page})"
    
    begin
      # Fetch repositories from GitHub API
      api_service = Github::GithubApiService.new(
        endpoint: "orgs/#{organization}/repos",
        params: build_params
      )
      
      response_data = api_service.call
      
      if response_data.is_a?(Array)
        repositories = response_data
        log_info "Fetched #{repositories.length} repositories from API"
        
        # Process and save repositories
        saved_count = process_and_save_repositories(repositories)
        
        {
          repositories: repositories,
          saved_count: saved_count,
          total_fetched: repositories.length,
          has_next_page: repositories.length == per_page,
          next_page: page + 1
        }
      else
        log_error "Unexpected API response format: #{response_data.class}"
        raise Github::ApiError, "Unexpected API response format"
      end
      
    rescue Github::NotFoundError => e
      log_error "Organization '#{organization}' not found: #{e.message}"
      raise Github::NotFoundError, "Organization '#{organization}' not found"
    rescue => e
      log_error "Failed to fetch repositories: #{e.message}"
      raise
    end
  end

  def build_params
    params = {
      page: page,
      per_page: per_page,
      sort: 'updated',
      direction: 'desc'
    }
    
    # Only include private repos if explicitly requested and we have permissions
    params[:type] = 'all' if include_private
    
    params
  end

  def process_and_save_repositories(repositories)
    saved_count = 0
    
    repositories.each do |repo_data|
      begin
        repository = find_or_create_repository(repo_data)
        
        if repository.persisted?
          saved_count += 1
          log_debug "Processed repository: #{repository.name}"
        else
          log_error "Failed to save repository #{repo_data['name']}: #{repository.errors.full_messages.join(', ')}"
        end
        
      rescue => e
        log_error "Error processing repository #{repo_data['name']}: #{e.message}"
        # Continue processing other repositories
      end
    end
    
    log_info "Successfully saved #{saved_count} out of #{repositories.length} repositories"
    saved_count
  end

  def find_or_create_repository(repo_data)
    # Find existing repository by GitHub ID
    repository = Repository.find_by(github_id: repo_data['id'].to_s)
    
    if repository
      # Update existing repository
      update_repository_attributes(repository, repo_data)
      repository.save!
      log_debug "Updated existing repository: #{repository.name}"
    else
      # Create new repository
      repository = create_new_repository(repo_data)
      log_debug "Created new repository: #{repository.name}"
    end
    
    repository
  end

  def create_new_repository(repo_data)
    Repository.create!(
      github_id: repo_data['id'].to_s,
      name: repo_data['name'],
      url: repo_data['html_url'],
      is_private: repo_data['private'],
      is_archived: repo_data['archived']
    )
  end

  def update_repository_attributes(repository, repo_data)
    repository.assign_attributes(
      name: repo_data['name'],
      url: repo_data['html_url'],
      is_private: repo_data['private'],
      is_archived: repo_data['archived']
    )
  end

  def validate_repository_data(repo_data)
    required_fields = %w[id name html_url private archived]
    missing_fields = required_fields - repo_data.keys
    
    if missing_fields.any?
      raise Github::ValidationError, "Missing required fields: #{missing_fields.join(', ')}"
    end
    
    # Validate GitHub ID is numeric
    unless repo_data['id'].to_s.match?(/^\d+$/)
      raise Github::ValidationError, "Invalid GitHub ID: #{repo_data['id']}"
    end
    
    # Validate URL format
    unless repo_data['html_url'].match?(/^https:\/\/github\.com\//)
      raise Github::ValidationError, "Invalid repository URL: #{repo_data['html_url']}"
    end
  end

  # Class method to fetch all repositories with pagination
  def self.fetch_all_repositories(organization: 'vercel', include_private: false)
    all_repositories = []
    page = 1
    total_saved = 0
    
    loop do
      Rails.logger.info "[Github::RepositoryService] Fetching page #{page} for organization #{organization}"
      
      service = new(
        organization: organization,
        page: page,
        per_page: 100,
        include_private: include_private
      )
      
      result = service.call
      
      all_repositories.concat(result[:repositories])
      total_saved += result[:saved_count]
      
      Rails.logger.info "[Github::RepositoryService] Page #{page}: #{result[:total_fetched]} fetched, #{result[:saved_count]} saved"
      
      unless result[:has_next_page]
        Rails.logger.info "[Github::RepositoryService] Reached end of repositories for organization #{organization}"
        break
      end
      
      page += 1
      
      # Safety check to prevent infinite loops
      if page > 1000
        Rails.logger.error "[Github::RepositoryService] Reached maximum page limit (1000). Stopping pagination."
        break
      end
    end
    
    {
      total_repositories: all_repositories.length,
      total_saved: total_saved,
      pages_processed: page
    }
  end

  private

  def log_info(message)
    Rails.logger.info "[Github::RepositoryService] #{message}"
  end

  def log_error(message)
    Rails.logger.error "[Github::RepositoryService] #{message}"
  end

  def log_debug(message)
    Rails.logger.debug "[Github::RepositoryService] #{message}"
  end
end
