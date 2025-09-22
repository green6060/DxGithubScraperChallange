module Analytics
  class DataAnalysisService < ApplicationService
    attribute :organization, :string, default: 'vercel'
    attribute :date_range, :string, default: '30_days' # 7_days, 30_days, 90_days, all_time
    attribute :include_private, :boolean, default: false

    def call
      log_info "Starting comprehensive data analysis for organization: #{organization}"
      
      begin
        analysis_results = {
          overview: generate_overview_stats,
          repository_analysis: analyze_repositories,
          pull_request_analysis: analyze_pull_requests,
          user_analysis: analyze_users,
          review_analysis: analyze_reviews,
          trends: analyze_trends,
          insights: generate_insights,
          generated_at: Time.current
        }
        
        log_info "Data analysis completed successfully"
        analysis_results
      rescue => e
        log_error "Data analysis failed: #{e.message}"
        raise e
      end
    end

    def self.generate_report(organization: 'vercel', date_range: '30_days')
      service = new(organization: organization, date_range: date_range)
      service.call
    end

    private

    def generate_overview_stats
      {
        total_repositories: Repository.count,
        total_pull_requests: PullRequest.count,
        total_reviews: Review.count,
        total_users: User.count,
        active_contributors: User.active_contributors.count,
        date_range: date_range,
        analysis_period: get_analysis_period
      }
    end

    def analyze_repositories
      repos = Repository.all
      
      {
        total_count: repos.count,
        public_count: repos.public_repos.count,
        private_count: repos.private_repos.count,
        active_count: repos.active.count,
        archived_count: repos.archived.count,
        most_active_repos: get_most_active_repositories,
        repository_health: calculate_repository_health,
        language_distribution: get_language_distribution
      }
    end

    def analyze_pull_requests
      prs = PullRequest.all
      
      {
        total_count: prs.count,
        open_count: prs.open.count,
        closed_count: prs.closed.count,
        merged_count: prs.merged.count,
        merge_rate: calculate_merge_rate(prs),
        average_pr_lifetime: calculate_average_pr_lifetime(prs),
        pr_velocity: calculate_pr_velocity(prs),
        top_contributors_by_prs: get_top_pr_contributors,
        pr_size_distribution: analyze_pr_sizes(prs)
      }
    end

    def analyze_users
      users = User.all
      
      {
        total_count: users.count,
        active_contributors: users.active_contributors.count,
        pr_authors: users.with_pull_requests.count,
        reviewers: users.with_reviews.count,
        users_with_profiles: users.with_profile.count,
        top_contributors: get_top_contributors_analysis,
        user_engagement: calculate_user_engagement,
        company_distribution: get_company_distribution,
        location_distribution: get_location_distribution
      }
    end

    def analyze_reviews
      reviews = Review.all
      
      {
        total_count: reviews.count,
        approved_count: reviews.approved.count,
        changes_requested_count: reviews.changes_requested.count,
        commented_count: reviews.commented.count,
        dismissed_count: reviews.dismissed.count,
        approval_rate: calculate_approval_rate(reviews),
        average_review_time: calculate_average_review_time(reviews),
        top_reviewers: get_top_reviewers,
        review_quality_metrics: calculate_review_quality_metrics(reviews)
      }
    end

    def analyze_trends
      {
        pr_trends: get_pr_trends,
        user_activity_trends: get_user_activity_trends,
        repository_activity_trends: get_repository_activity_trends,
        seasonal_patterns: get_seasonal_patterns
      }
    end

    def generate_insights
      insights = []
      
      # Repository insights
      repo_stats = analyze_repositories
      if repo_stats[:archived_count] > 0
        insights << {
          type: 'repository',
          message: "#{repo_stats[:archived_count]} repositories are archived (#{(repo_stats[:archived_count].to_f / repo_stats[:total_count] * 100).round(1)}% of total)",
          priority: 'info'
        }
      end
      
      # PR insights
      pr_stats = analyze_pull_requests
      if pr_stats[:merge_rate] < 0.5
        insights << {
          type: 'pull_request',
          message: "Low merge rate: #{(pr_stats[:merge_rate] * 100).round(1)}% of PRs are merged",
          priority: 'warning'
        }
      end
      
      # User insights
      user_stats = analyze_users
      if user_stats[:users_with_profiles] < user_stats[:total_count] * 0.3
        insights << {
          type: 'user',
          message: "Only #{(user_stats[:users_with_profiles].to_f / user_stats[:total_count] * 100).round(1)}% of users have complete profiles",
          priority: 'info'
        }
      end
      
      insights
    end

    # Helper methods for calculations
    def get_analysis_period
      case date_range
      when '7_days'
        7.days.ago..Time.current
      when '30_days'
        30.days.ago..Time.current
      when '90_days'
        90.days.ago..Time.current
      else
        nil # all_time
      end
    end

    def get_most_active_repositories
      Repository.joins(:pull_requests)
                .group('repositories.id, repositories.name')
                .order('COUNT(pull_requests.id) DESC')
                .limit(10)
                .pluck('repositories.name', 'COUNT(pull_requests.id)')
                .map { |name, count| { name: name, pr_count: count } }
    end

    def calculate_repository_health
      total_repos = Repository.count
      return 0 if total_repos.zero?
      
      active_repos = Repository.active.count
      (active_repos.to_f / total_repos * 100).round(1)
    end

    def get_language_distribution
      # This would require language data from GitHub API
      # For now, return a placeholder
      { 'Unknown' => Repository.count }
    end

    def calculate_merge_rate(prs)
      return 0 if prs.count.zero?
      prs.merged.count.to_f / prs.count
    end

    def calculate_average_pr_lifetime(prs)
      closed_prs = prs.closed.where.not(closed_at: nil)
      return 0 if closed_prs.empty?
      
      lifetimes = closed_prs.map do |pr|
        (pr.closed_at - pr.created_at) / 1.day
      end
      
      (lifetimes.sum / lifetimes.count).round(1)
    end

    def calculate_pr_velocity(prs)
      period = get_analysis_period
      return 0 unless period
      
      prs_in_period = prs.where(created_at: period)
      days = (period.end - period.begin) / 1.day
      (prs_in_period.count.to_f / days).round(2)
    end

    def get_top_pr_contributors
      User.joins(:authored_pull_requests)
          .group('users.id, users.login, users.name')
          .order('COUNT(pull_requests.id) DESC')
          .limit(10)
          .pluck('users.login', 'users.name', 'COUNT(pull_requests.id)')
          .map { |login, name, count| { login: login, name: name, pr_count: count } }
    end

    def analyze_pr_sizes(prs)
      {
        small: prs.where('additions + deletions < 50').count,
        medium: prs.where('additions + deletions BETWEEN 50 AND 200').count,
        large: prs.where('additions + deletions > 200').count
      }
    end

    def get_top_contributors_analysis
      User.top_contributors.limit(10).map do |user|
        {
          login: user.login,
          name: user.display_name,
          total_contributions: user.total_contributions,
          pr_count: user.authored_pull_requests.count,
          review_count: user.reviews.count,
          followers: user.followers || 0
        }
      end
    end

    def calculate_user_engagement
      total_users = User.count
      return 0 if total_users.zero?
      
      active_users = User.active_contributors.count
      (active_users.to_f / total_users * 100).round(1)
    end

    def get_company_distribution
      User.where.not(company: [nil, ''])
          .group(:company)
          .count
          .sort_by { |_, count| -count }
          .first(10)
    end

    def get_location_distribution
      User.where.not(location: [nil, ''])
          .group(:location)
          .count
          .sort_by { |_, count| -count }
          .first(10)
    end

    def calculate_approval_rate(reviews)
      return 0 if reviews.count.zero?
      reviews.approved.count.to_f / reviews.count
    end

    def calculate_average_review_time(reviews)
      submitted_reviews = reviews.where.not(submitted_at: nil)
      return 0 if submitted_reviews.empty?
      
      # This would need PR creation time to calculate properly
      # For now, return a placeholder
      0
    end

    def get_top_reviewers
      User.joins(:reviews)
          .group('users.id, users.login, users.name')
          .order('COUNT(reviews.id) DESC')
          .limit(10)
          .pluck('users.login', 'users.name', 'COUNT(reviews.id)')
          .map { |login, name, count| { login: login, name: name, review_count: count } }
    end

    def calculate_review_quality_metrics(reviews)
      {
        average_reviews_per_pr: calculate_average_reviews_per_pr,
        review_coverage: calculate_review_coverage,
        review_distribution: {
          approved: reviews.approved.count,
          changes_requested: reviews.changes_requested.count,
          commented: reviews.commented.count,
          dismissed: reviews.dismissed.count
        }
      }
    end

    def calculate_average_reviews_per_pr
      total_prs = PullRequest.count
      return 0 if total_prs.zero?
      Review.count.to_f / total_prs
    end

    def calculate_review_coverage
      total_prs = PullRequest.count
      return 0 if total_prs.zero?
      
      prs_with_reviews = PullRequest.joins(:reviews).distinct.count
      (prs_with_reviews.to_f / total_prs * 100).round(1)
    end

    def get_pr_trends
      # Group PRs by month for trend analysis
      PullRequest.group_by_month(:created_at, last: 12).count
    end

    def get_user_activity_trends
      # Group user activity by month
      User.group_by_month(:updated_at, last: 12).count
    end

    def get_repository_activity_trends
      # Group repository activity by month
      Repository.group_by_month(:updated_at, last: 12).count
    end

    def get_seasonal_patterns
      # Analyze activity by day of week and month
      {
        by_day_of_week: PullRequest.group_by_day_of_week(:created_at).count,
        by_month: PullRequest.group_by_month(:created_at).count
      }
    end

    def log_info(message)
      Rails.logger.info "[#{self.class.name}] #{message}"
    end

    def log_error(message)
      Rails.logger.error "[#{self.class.name}] #{message}"
    end
  end
end
