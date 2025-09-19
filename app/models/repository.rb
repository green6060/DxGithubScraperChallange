class Repository < ApplicationRecord
    # Validations
    validates :github_id, presence: true, uniqueness: true
    validates :name, presence: true
    validates :url, presence: true, format: { with: URI::regexp(%w[http https]) }
    validates :is_private, inclusion: { in: [true, false] }
    validates :is_archived, inclusion: { in: [true, false] }

    # Associations
    has_many :pull_requests, dependent: :destroy

    # Scopes
    scope :public_repos, -> { where(is_private: false) }
    scope :private_repos, -> { where(is_private: true) }
    scope :archived, -> { where(is_archived: true) }
    scope :active, -> { where(is_archived: false) }

    # Instance methods
    def public?
        !is_private
    end

    def archived?
        is_archived
    end
end
