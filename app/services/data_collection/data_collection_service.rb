# Data Collection Service - Orchestrates the data collection workflow
class DataCollection::DataCollectionService < ApplicationService
  attribute :organization, :string, default: 'vercel'
  attribute :max_repositories, :integer, default: 10
  attribute :max_pull_requests_per_repo, :integer, default: 20
  attribute :include_reviews, :boolean, default: true
  attribute :dry_run, :boolean, default: false

  def call
    log_info "Starting comprehensive data collection for organization: #{organization}"
    
    begin
      # Step 1: Collect repositories
      repositories = collect_repositories
      
      # Step 2: Collect pull requests for each repository
      pull_requests = collect_pull_requests(repositories)
      
      # Step 3: Collect reviews if requested
      reviews = collect_reviews(repositories) if include_reviews
      
      {
        success: true,
        repositories_count: repositories.length,
        pull_requests_count: pull_requests,
        reviews_count: reviews || 0,
        message: "Data collection completed successfully"
      }
    rescue => e
      log_error "Data collection failed: #{e.message}"
      {
        success: false,
        error: e.message,
        message: "Data collection failed"
      }
    end
  end

  def self.collect_all_data(organization: 'vercel', max_repos: 10, max_prs: 20, include_reviews: true)
    service = new(
      organization: organization,
      max_repositories: max_repos,
      max_pull_requests_per_repo: max_prs,
      include_reviews: include_reviews
    )
    service.call
  end

  private

  def collect_repositories
    log_info "Collecting repositories for organization: #{organization}"
    
    # First, ensure we have repositories in the database
    result = Github::RepositoryService.fetch_all_repositories(organization: organization)
    log_info "Repository collection result: #{result}"
    
    # Get repositories from database
    repositories = Repository.all
    log_info "Found #{repositories.length} repositories in database"
    
    repositories
  end

  def collect_pull_requests(repositories)
    log_info "Collecting pull requests for #{repositories.length} repositories"
    
    total_pull_requests = 0
    processed_repos = 0
    
    repositories.first(max_repositories).each do |repo|
      begin
        repo_name = "vercel/#{repo.name}"
        log_info "Processing repository: #{repo_name}"
        
        pull_requests = Github::PullRequestService.fetch_all_pull_requests(
          repo_name, 
          max_pages: (max_pull_requests_per_repo / 100.0).ceil
        )
        
        total_pull_requests += pull_requests.length
        processed_repos += 1
        
        log_info "Collected #{pull_requests.length} pull requests for #{repo_name}"
        
        # Add a small delay to be respectful to the API
        sleep(1) unless dry_run
        
      rescue => e
        log_error "Failed to collect pull requests for #{repo.name}: #{e.message}"
        # Continue with next repository
      end
    end
    
    log_info "Completed pull request collection: #{total_pull_requests} total PRs from #{processed_repos} repositories"
    total_pull_requests
  end

  def collect_reviews(repositories)
    log_info "Collecting reviews for repositories"
    
    total_reviews = 0
    processed_repos = 0
    
    repositories.first(max_repositories).each do |repo|
      begin
        repo_name = "vercel/#{repo.name}"
        log_info "Processing reviews for repository: #{repo_name}"
        
        reviews_count = Github::ReviewService.fetch_reviews_for_repository(repo_name)
        total_reviews += reviews_count
        processed_repos += 1
        
        log_info "Collected #{reviews_count} reviews for #{repo_name}"
        
        # Add a small delay to be respectful to the API
        sleep(1) unless dry_run
        
      rescue => e
        log_error "Failed to collect reviews for #{repo.name}: #{e.message}"
        # Continue with next repository
      end
    end
    
    log_info "Completed review collection: #{total_reviews} total reviews from #{processed_repos} repositories"
    total_reviews
  end

  def log_info(message)
    Rails.logger.info "[#{self.class.name}] #{message}"
  end

  def log_error(message)
    Rails.logger.error "[#{self.class.name}] #{message}"
  end
end
