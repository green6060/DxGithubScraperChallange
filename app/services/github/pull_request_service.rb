module Github
  class PullRequestService < ApplicationService
    attribute :repository, :string
    attribute :page, :integer, default: 1
    attribute :per_page, :integer, default: 100
    attribute :state, :string, default: 'all' # all, open, closed

    def call
      log_info "Fetching pull requests for repository: #{repository} (page #{page})"
      
      begin
        pull_requests_data = fetch_pull_requests_page
        process_pull_requests(pull_requests_data)
        
        {
          success: true,
          pull_requests: pull_requests_data,
          count: pull_requests_data.length,
          page: page
        }
      rescue => e
        log_error "Failed to fetch pull requests: #{e.message}"
        raise e
      end
    end

    def self.fetch_all_pull_requests(repository_name, max_pages: 10)
      Rails.logger.info "[#{self.name}] Starting pull request collection for repository: #{repository_name}"
      
      all_pull_requests = []
      page = 1
      
      begin
        loop do
          break if page > max_pages
          
          service = new(repository: repository_name, page: page)
          result = service.call
          
          pull_requests = result[:pull_requests]
          break if pull_requests.empty?
          
          all_pull_requests.concat(pull_requests)
          Rails.logger.info "[#{self.name}] Fetched page #{page}: #{pull_requests.length} pull requests"
          
          page += 1
        end
        
        Rails.logger.info "[#{self.name}] Completed pull request collection: #{all_pull_requests.length} total pull requests"
        all_pull_requests
      rescue => e
        Rails.logger.error "[#{self.name}] Failed to collect all pull requests: #{e.message}"
        raise e
      end
    end

    private

    def fetch_pull_requests_page
      endpoint = "repos/#{repository}/pulls"
      params = {
        state: state,
        page: page,
        per_page: per_page,
        sort: 'updated',
        direction: 'desc'
      }
      
      api_service = GithubApiService.new(endpoint: endpoint, params: params)
      api_service.call
    end

    def process_pull_requests(pull_requests_data)
      return [] if pull_requests_data.nil? || pull_requests_data.empty?
      
      pull_requests_data.each do |pr_data|
        begin
          save_pull_request(pr_data)
        rescue => e
          log_error "Failed to save pull request #{pr_data['number']}: #{e.message}"
          # Continue processing other PRs
        end
      end
    end

    def save_pull_request(pr_data)
      return unless validate_pull_request_data(pr_data)
      
      # Find or create the repository
      repo = Repository.find_by(github_id: pr_data['base']['repo']['id'].to_s)
      return unless repo
      
      # Find or create the author
      author_data = pr_data['user']
      author = find_or_create_user(author_data)
      return unless author
      
      # Create or update pull request
      pull_request = PullRequest.find_or_initialize_by(github_id: pr_data['id'].to_s)
      
      pull_request.assign_attributes(
        repository: repo,
        number: pr_data['number'],
        title: pr_data['title'],
        author: author,
        closed_at: pr_data['closed_at'] ? Time.parse(pr_data['closed_at']) : nil,
        merged_at: pr_data['merged_at'] ? Time.parse(pr_data['merged_at']) : nil,
        additions: pr_data['additions'] || 0,
        deletions: pr_data['deletions'] || 0,
        changed_files: pr_data['changed_files'] || 0,
        commit_count: pr_data['commits'] || 0
      )
      
      if pull_request.save
        log_debug "Saved pull request: #{pr_data['number']} - #{pr_data['title']}"
      else
        log_error "Failed to save pull request #{pr_data['number']}: #{pull_request.errors.full_messages.join(', ')}"
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

    def validate_pull_request_data(pr_data)
      required_fields = ['id', 'number', 'title', 'user', 'base']
      
      missing_fields = required_fields.select { |field| pr_data[field].nil? }
      
      if missing_fields.any?
        log_error "Missing required fields for PR: #{missing_fields.join(', ')}"
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
