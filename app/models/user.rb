class User < ApplicationRecord
    # Validations
    validates :github_id, presence: true, uniqueness: true
    validates :login, presence: true, uniqueness: true
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
    validates :public_repos, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :public_gists, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :followers, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :following, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :blog, format: { with: URI::regexp(%w[http https]) }, allow_blank: true
  
    # Associations
    has_many :authored_pull_requests, class_name: 'PullRequest', foreign_key: 'author_id', dependent: :nullify
    has_many :reviews, foreign_key: 'reviewer_id', dependent: :nullify
  
    # Scopes
    scope :with_pull_requests, -> { joins(:authored_pull_requests).distinct }
    scope :with_reviews, -> { joins(:reviews).distinct }
    scope :active_contributors, -> { where(id: User.joins(:authored_pull_requests).select(:id)).or(where(id: User.joins(:reviews).select(:id))).distinct }
    scope :with_profile, -> { where.not(name: [nil, '']) }
    scope :by_company, ->(company) { where(company: company) }
    scope :by_location, ->(location) { where(location: location) }
    scope :top_contributors, -> { order(Arel.sql('(SELECT COUNT(*) FROM pull_requests WHERE author_id = users.id) + (SELECT COUNT(*) FROM reviews WHERE reviewer_id = users.id) DESC')) }
    scope :recent_contributors, -> { order(updated_at: :desc) }
  
    # Instance methods
    def has_authored_prs?
      authored_pull_requests.exists?
    end
  
    def has_reviews?
      reviews.exists?
    end
  
    def total_contributions
      authored_pull_requests.count + reviews.count
    end
  
    def display_name
      name.present? ? name : login
    end
  
    def profile_complete?
      name.present? && bio.present? && location.present?
    end
  
    def has_social_links?
      blog.present? || twitter_username.present?
    end
  
    def contribution_ratio
      return 0 if following.zero?
      followers.to_f / following
    end
  
    def github_profile_url
      "https://github.com/#{login}"
    end
  
    def twitter_url
      return nil unless twitter_username.present?
      "https://twitter.com/#{twitter_username}"
    end
  end