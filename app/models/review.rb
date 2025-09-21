class Review < ApplicationRecord
  # Validations
  validates :github_id, presence: true, uniqueness: true
  validates :pull_request_id, presence: true
  validates :reviewer_id, presence: true
  validates :state, presence: true, inclusion: { 
    in: %w[approved changes_requested commented dismissed],
    message: "must be one of: approved, changes_requested, commented, dismissed"
  }

  # Associations
  belongs_to :pull_request
  belongs_to :reviewer, class_name: 'User'

  # Scopes
  scope :approved, -> { where(state: 'approved') }
  scope :changes_requested, -> { where(state: 'changes_requested') }
  scope :commented, -> { where(state: 'commented') }
  scope :dismissed, -> { where(state: 'dismissed') }
  scope :by_reviewer, ->(user_id) { where(reviewer_id: user_id) }
  scope :recent, -> { order(submitted_at: :desc) }

  # Instance methods
  def approved?
    state == 'approved'
  end

  def changes_requested?
    state == 'changes_requested'
  end

  def commented?
    state == 'commented'
  end

  def dismissed?
    state == 'dismissed'
  end

  def submitted?
    submitted_at.present?
  end

  def pending?
    submitted_at.nil?
  end
end