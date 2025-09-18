# Data Collection Service - Orchestrates the data collection workflow
class DataCollection::DataCollectionService < ApplicationService
  attribute :organization, :string, default: 'vercel'
  attribute :dry_run, :boolean, default: false

  def initialize(organization: 'vercel', dry_run: false)
    super
    @organization = organization
    @dry_run = dry_run
  end

  def call
    log_info "Starting data collection for organization: #{organization}"
    
    # This will be implemented in Ticket 13
    # Workflow: repos → PRs → reviews → users
    raise NotImplementedError, "Data collection workflow will be implemented in Ticket 13"
  end

  private

  def collect_repositories
    # Will be implemented in Ticket 6
    log_info "Collecting repositories..."
  end

  def collect_pull_requests
    # Will be implemented in Ticket 7
    log_info "Collecting pull requests..."
  end

  def collect_reviews
    # Will be implemented in Ticket 9
    log_info "Collecting reviews..."
  end

  def collect_users
    # Will be implemented in Ticket 11
    log_info "Collecting users..."
  end
end
