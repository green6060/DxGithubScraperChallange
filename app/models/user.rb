class User < ApplicationRecord
    # Validations
    validates :github_id, presence: true, uniqueness: true
    validates :login, presence: true, uniqueness: true
  
    # Associations
    has_many :authored_pull_requests, class_name: 'PullRequest', foreign_key: 'author_id', dependent: :nullify
    has_many :reviews, foreign_key: 'reviewer_id', dependent: :nullify
  
    # Scopes
    scope :with_pull_requests, -> { joins(:authored_pull_requests).distinct }
    scope :with_reviews, -> { joins(:reviews).distinct }
    scope :active_contributors, -> { joins(:authored_pull_requests).or(joins(:reviews)).distinct }
  
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
      login
    end
  end