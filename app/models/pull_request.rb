class PullRequest < ApplicationRecord
    # Validations
    validates :github_id, presence: true, uniqueness: true
    validates :number, presence: true, numericality: { greater_than: 0 }
    validates :title, presence: true
    validates :repository_id, presence: true
    validates :author_id, presence: true
    validates :additions, numericality: { greater_than_or_equal_to: 0 }
    validates :deletions, numericality: { greater_than_or_equal_to: 0 }
    validates :changed_files, numericality: { greater_than_or_equal_to: 0 }
    validates :commit_count, numericality: { greater_than_or_equal_to: 0 }

    # Associations
    belongs_to :repository
    belongs_to :author, class_name: 'User'
    has_many :reviews, dependent: :destroy

    # Scopes
    scope :open, -> { where(closed_at: nil) }
    scope :closed, -> { where.not(closed_at: nil) }
    scope :merged, -> { where.not(merged_at: nil) }
    scope :by_repository, ->(repo_id) { where(repository_id: repo_id) }

    # Instance methods
    def open?
        closed_at.nil?
    end

    def closed?
        !closed_at.nil?
    end

    def merged?
        !merged_at.nil?
    end

    def total_changes
        additions + deletions
    end
end
