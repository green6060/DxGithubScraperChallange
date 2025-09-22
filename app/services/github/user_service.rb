module Github
  class UserService < ApplicationService
    attribute :username, :string
    attribute :page, :integer, default: 1
    attribute :per_page, :integer, default: 100

    def call
      log_info "Fetching user profile for: #{username}"
      
      begin
        user_data = fetch_user_profile
        save_user_profile(user_data)
        
        {
          success: true,
          user: user_data,
          message: "User profile fetched and saved successfully"
        }
      rescue => e
        log_error "Failed to fetch user profile: #{e.message}"
        raise e
      end
    end

    def self.fetch_user_profile(username)
      service = new(username: username)
      service.call
    end

    def self.fetch_all_users_from_contributors
      Rails.logger.info "[#{self.name}] Starting user profile collection from existing contributors"
      
      # Get all unique users who have authored PRs or reviews
      pr_user_ids = User.joins(:authored_pull_requests).distinct.pluck(:github_id)
      review_user_ids = User.joins(:reviews).distinct.pluck(:github_id)
      user_ids = (pr_user_ids + review_user_ids).uniq
      
      Rails.logger.info "[#{self.name}] Found #{user_ids.length} users to fetch profiles for"
      
      total_updated = 0
      
      user_ids.each do |github_id|
        begin
          # Get the user from our database to get their login
          user = User.find_by(github_id: github_id)
          next unless user
          
          # Fetch their full profile from GitHub
          result = fetch_user_profile(user.login)
          total_updated += 1
          
          Rails.logger.info "[#{self.name}] Updated profile for user: #{user.login}"
          
          # Add a small delay to be respectful to the API
          sleep(0.5)
          
        rescue => e
          Rails.logger.error "[#{self.name}] Failed to fetch profile for user #{github_id}: #{e.message}"
          # Continue with next user
        end
      end
      
      Rails.logger.info "[#{self.name}] Completed user profile collection: #{total_updated} profiles updated"
      total_updated
    end

    def self.fetch_users_from_organization(organization, max_users: 100)
      Rails.logger.info "[#{self.name}] Starting user collection from organization: #{organization}"
      
      # Get all unique users from repositories in the organization
      user_ids = User.joins(authored_pull_requests: :repository)
                    .where(repositories: { name: organization })
                    .distinct
                    .pluck(:github_id)
                    .first(max_users)
      
      Rails.logger.info "[#{self.name}] Found #{user_ids.length} users from organization #{organization}"
      
      total_updated = 0
      
      user_ids.each do |github_id|
        begin
          user = User.find_by(github_id: github_id)
          next unless user
          
          result = fetch_user_profile(user.login)
          total_updated += 1
          
          Rails.logger.info "[#{self.name}] Updated profile for user: #{user.login}"
          
          sleep(0.5)
          
        rescue => e
          Rails.logger.error "[#{self.name}] Failed to fetch profile for user #{github_id}: #{e.message}"
        end
      end
      
      Rails.logger.info "[#{self.name}] Completed organization user collection: #{total_updated} profiles updated"
      total_updated
    end

    private

    def fetch_user_profile
      endpoint = "users/#{username}"
      
      api_service = GithubApiService.new(endpoint: endpoint)
      api_service.call
    end

    def save_user_profile(user_data)
      return unless validate_user_data(user_data)
      
      user = User.find_or_initialize_by(github_id: user_data['id'].to_s)
      
      # Update user profile with additional data
      user.assign_attributes(
        login: user_data['login'],
        name: user_data['name'],
        email: user_data['email'],
        bio: user_data['bio'],
        company: user_data['company'],
        location: user_data['location'],
        blog: user_data['blog'],
        twitter_username: user_data['twitter_username'],
        public_repos: user_data['public_repos'],
        public_gists: user_data['public_gists'],
        followers: user_data['followers'],
        following: user_data['following'],
        github_created_at: user_data['created_at'] ? Time.parse(user_data['created_at']) : nil,
        github_updated_at: user_data['updated_at'] ? Time.parse(user_data['updated_at']) : nil
      )
      
      if user.save
        log_debug "Saved/updated user profile: #{user_data['login']}"
      else
        log_error "Failed to save user profile #{user_data['login']}: #{user.errors.full_messages.join(', ')}"
      end
      
      user
    end

    def validate_user_data(user_data)
      required_fields = ['id', 'login']
      
      missing_fields = required_fields.select { |field| user_data[field].nil? }
      
      if missing_fields.any?
        log_error "Missing required fields for user: #{missing_fields.join(', ')}"
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
