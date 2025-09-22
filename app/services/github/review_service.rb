module Github
  class ReviewService < ApplicationService
    attribute :repository, :string
    attribute :pull_request_number, :integer
    attribute :page, :integer, default: 1
    attribute :per_page, :integer, default: 100

    def call
      log_info "Fetching reviews for PR ##{pull_request_number} in #{repository} (page #{page})"
      
      begin
        reviews_data = fetch_reviews_page
        process_reviews(reviews_data)
        
        {
          success: true,
          reviews: reviews_data,
          count: reviews_data.length,
          page: page
        }
      rescue => e
        log_error "Failed to fetch reviews: #{e.message}"
        raise e
      end
    end

    def self.fetch_all_reviews_for_pr(repository_name, pull_request_number)
      Rails.logger.info "[#{self.name}] Starting review collection for PR ##{pull_request_number} in #{repository_name}"
      
      all_reviews = []
      page = 1
      
      begin
        loop do
          service = new(
            repository: repository_name, 
            pull_request_number: pull_request_number, 
            page: page
          )
          result = service.call
          
          reviews = result[:reviews]
          break if reviews.empty?
          
          all_reviews.concat(reviews)
          Rails.logger.info "[#{self.name}] Fetched page #{page}: #{reviews.length} reviews"
          
          page += 1
        end
        
        Rails.logger.info "[#{self.name}] Completed review collection: #{all_reviews.length} total reviews"
        all_reviews
      rescue => e
        Rails.logger.error "[#{self.name}] Failed to collect all reviews: #{e.message}"
        raise e
      end
    end

    def self.fetch_reviews_for_repository(repository_name, max_pages: 5)
      Rails.logger.info "[#{self.name}] Starting review collection for all PRs in repository: #{repository_name}"
      
      # Get all pull requests for this repository
      pull_requests = PullRequest.joins(:repository)
                                .where(repositories: { name: repository_name })
                                .limit(50) # Limit to avoid too many API calls
      
      total_reviews = 0
      
      pull_requests.each do |pr|
        begin
          reviews = fetch_all_reviews_for_pr(repository_name, pr.number)
          total_reviews += reviews.length
          Rails.logger.info "[#{self.name}] Collected #{reviews.length} reviews for PR ##{pr.number}"
        rescue => e
          Rails.logger.error "[#{self.name}] Failed to collect reviews for PR ##{pr.number}: #{e.message}"
          # Continue with next PR
        end
      end
      
      Rails.logger.info "[#{self.name}] Completed review collection for repository: #{total_reviews} total reviews"
      total_reviews
    end

    private

    def fetch_reviews_page
      endpoint = "repos/#{repository}/pulls/#{pull_request_number}/reviews"
      params = {
        page: page,
        per_page: per_page
      }
      
      api_service = GithubApiService.new(endpoint: endpoint, params: params)
      api_service.call
    end

    def process_reviews(reviews_data)
      return [] if reviews_data.nil? || reviews_data.empty?
      
      reviews_data.each do |review_data|
        begin
          save_review(review_data)
        rescue => e
          log_error "Failed to save review #{review_data['id']}: #{e.message}"
          # Continue processing other reviews
        end
      end
    end

    def save_review(review_data)
      return unless validate_review_data(review_data)
      
      # Find the pull request
      pr = PullRequest.joins(:repository)
                     .where(repositories: { name: repository }, number: pull_request_number)
                     .first
      return unless pr
      
      # Find or create the reviewer
      reviewer_data = review_data['user']
      reviewer = find_or_create_user(reviewer_data)
      return unless reviewer
      
      # Create or update review
      review = Review.find_or_initialize_by(github_id: review_data['id'].to_s)
      
      # Map GitHub review state to our enum
      state = map_review_state(review_data['state'])
      
      review.assign_attributes(
        pull_request: pr,
        reviewer: reviewer,
        state: state,
        submitted_at: review_data['submitted_at'] ? Time.parse(review_data['submitted_at']) : nil
      )
      
      if review.save
        log_debug "Saved review: #{review_data['id']} - #{state}"
      else
        log_error "Failed to save review #{review_data['id']}: #{review.errors.full_messages.join(', ')}"
      end
    end

    def find_or_create_user(user_data)
      return nil unless user_data && user_data['id']
      
      user = User.find_or_initialize_by(github_id: user_data['id'].to_s)
      
      if user.new_record? || user.login != user_data['login']
        user.login = user_data['login']
        user.save!
        log_debug "Created/updated user: #{user_data['login']}"
      end
      
      user
    end

    def map_review_state(github_state)
      case github_state
      when 'APPROVED'
        'approved'
      when 'CHANGES_REQUESTED'
        'changes_requested'
      when 'COMMENTED'
        'commented'
      when 'DISMISSED'
        'dismissed'
      else
        'commented' # Default fallback
      end
    end

    def validate_review_data(review_data)
      required_fields = ['id', 'user', 'state']
      
      missing_fields = required_fields.select { |field| review_data[field].nil? }
      
      if missing_fields.any?
        log_error "Missing required fields for review: #{missing_fields.join(', ')}"
        return false
      end
      
      true
    end

    def log_info(message)
      Rails.logger.info "[#{self.class.name}] #{message}"
    end

    def log_debug(message)
      Rails.logger.debug "[#{self.class.name}] #{message}"
    end

    def log_error(message)
      Rails.logger.error "[#{self.class.name}] #{message}"
    end
  end
end
