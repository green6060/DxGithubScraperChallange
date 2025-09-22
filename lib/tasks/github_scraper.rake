namespace :github_scraper do
  desc "Collect data from GitHub for Vercel organization"
  task collect: :environment do
    puts "Starting GitHub data collection..."
    
    service = DataCollection::DataCollectionService.new(
      organization: ENV.fetch('GITHUB_ORGANIZATION', 'vercel'),
      dry_run: ENV.fetch('DRY_RUN', 'false') == 'true'
    )
    
    begin
      service.call
      puts "Data collection completed successfully!"
    rescue => e
      puts "Data collection failed: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Show current configuration"
  task config: :environment do
    puts "GitHub API Configuration:"
    puts "  Base URL: #{Rails.application.config.github_api[:base_url]}"
    puts "  Token: #{Rails.application.config.github_api[:token].present? ? '[SET]' : '[NOT SET]'}"
    puts "  Rate Limit: #{Rails.application.config.github_api[:rate_limit_requests_per_hour]} requests/hour"
    puts "  Max Retries: #{Rails.application.config.github_api[:rate_limit_max_retries]}"
  end

  desc "Test GitHub API connection"
  task test_connection: :environment do
    puts "Testing GitHub API connection..."
    # This will be implemented when we add the actual API service
    puts "API connection test will be implemented in Ticket 4"
  end

  desc "Collect repositories for an organization"
  task :collect_repositories, [:organization] => :environment do |t, args|
    organization = args[:organization] || ENV.fetch('GITHUB_ORGANIZATION', 'vercel')
    include_private = ENV.fetch('INCLUDE_PRIVATE', 'false') == 'true'
    
    puts "Starting repository collection for organization: #{organization}"
    puts "Include private repositories: #{include_private}"
    
    begin
      result = Github::RepositoryService.fetch_all_repositories(
        organization: organization,
        include_private: include_private
      )
      
      puts "\n=== Repository Collection Complete ==="
      puts "Total repositories fetched: #{result[:total_repositories]}"
      puts "Total repositories saved: #{result[:total_saved]}"
      puts "Pages processed: #{result[:pages_processed]}"
      
      if result[:total_saved] > 0
        puts "\nSample of collected repositories:"
        Repository.limit(5).each do |repo|
          puts "  - #{repo.name} (#{repo.is_private? ? 'private' : 'public'})"
        end
      end
      
    rescue => e
      puts "Repository collection failed: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Collect pull requests for a specific repository"
  task :collect_pull_requests, [:repository] => :environment do |task, args|
    repository = args[:repository]
    
    unless repository
      puts "❌ Please specify a repository: rails github_scraper:collect_pull_requests[vercel/next.js]"
      exit 1
    end
    
    puts "🚀 Starting pull request collection for repository: #{repository}"
    
    begin
      pull_requests = Github::PullRequestService.fetch_all_pull_requests(repository)
      puts "✅ Successfully collected #{pull_requests.length} pull requests"
      
      # Display some statistics
      puts "\n📊 Collection Statistics:"
      puts "  Total pull requests: #{PullRequest.count}"
      puts "  Open pull requests: #{PullRequest.open.count}"
      puts "  Closed pull requests: #{PullRequest.closed.count}"
      puts "  Merged pull requests: #{PullRequest.merged.count}"
      
    rescue => e
      puts "❌ Pull request collection failed: #{e.message}"
      puts "   Error type: #{e.class.name}"
      exit 1
    end
  end

  desc "Collect reviews for a specific pull request"
  task :collect_reviews, [:repository, :pull_request_number] => :environment do |task, args|
    repository = args[:repository]
    pr_number = args[:pull_request_number]
    
    unless repository && pr_number
      puts "❌ Please specify repository and PR number: rails github_scraper:collect_reviews[vercel/next.js,123]"
      exit 1
    end
    
    puts "🚀 Starting review collection for PR ##{pr_number} in #{repository}"
    
    begin
      reviews = Github::ReviewService.fetch_all_reviews_for_pr(repository, pr_number.to_i)
      puts "✅ Successfully collected #{reviews.length} reviews"
      
      # Display some statistics
      puts "\n📊 Collection Statistics:"
      puts "  Total reviews: #{Review.count}"
      puts "  Approved reviews: #{Review.approved.count}"
      puts "  Changes requested: #{Review.changes_requested.count}"
      puts "  Commented reviews: #{Review.commented.count}"
      puts "  Dismissed reviews: #{Review.dismissed.count}"
      
    rescue => e
      puts "❌ Review collection failed: #{e.message}"
      puts "   Error type: #{e.class.name}"
      exit 1
    end
  end

  desc "Collect user profiles for existing contributors"
  task :collect_user_profiles, [:max_users] => :environment do |task, args|
    max_users = (args[:max_users] || 50).to_i
    
    puts "🚀 Starting user profile collection"
    puts "   Max users: #{max_users}"
    
    begin
      updated_count = Github::UserService.fetch_all_users_from_contributors
      
      puts "✅ User profile collection completed successfully!"
      puts "\n📊 Collection Statistics:"
      puts "  Profiles updated: #{updated_count}"
      puts "  Total users: #{User.count}"
      puts "  Users with profiles: #{User.with_profile.count}"
      puts "  Top contributors: #{User.top_contributors.limit(5).pluck(:login).join(', ')}"
      
    rescue => e
      puts "❌ User profile collection failed: #{e.message}"
      puts "   Error type: #{e.class.name}"
      exit 1
    end
  end

  desc "Collect user profiles from organization"
  task :collect_organization_users, [:organization, :max_users] => :environment do |task, args|
    organization = args[:organization] || 'vercel'
    max_users = (args[:max_users] || 50).to_i
    
    puts "🚀 Starting organization user profile collection"
    puts "   Organization: #{organization}"
    puts "   Max users: #{max_users}"
    
    begin
      updated_count = Github::UserService.fetch_users_from_organization(organization, max_users: max_users)
      
      puts "✅ Organization user collection completed successfully!"
      puts "\n📊 Collection Statistics:"
      puts "  Profiles updated: #{updated_count}"
      puts "  Total users: #{User.count}"
      puts "  Users with complete profiles: #{User.where.not(name: [nil, '']).count}"
      
    rescue => e
      puts "❌ Organization user collection failed: #{e.message}"
      puts "   Error type: #{e.class.name}"
      exit 1
    end
  end

  desc "Run comprehensive data collection (repos + PRs + reviews + users)"
  task :collect_all, [:organization, :max_repos, :max_prs, :max_users] => :environment do |task, args|
    organization = args[:organization] || 'vercel'
    max_repos = (args[:max_repos] || 5).to_i
    max_prs = (args[:max_prs] || 10).to_i
    max_users = (args[:max_users] || 50).to_i
    
    puts "🚀 Starting comprehensive data collection"
    puts "   Organization: #{organization}"
    puts "   Max repositories: #{max_repos}"
    puts "   Max PRs per repo: #{max_prs}"
    puts "   Max users: #{max_users}"
    puts "   Includes reviews: true"
    puts "   Includes user profiles: true"
    
    begin
      # First collect repositories, PRs, and reviews
      result = DataCollection::DataCollectionService.collect_all_data(
        organization: organization,
        max_repos: max_repos,
        max_prs: max_prs,
        include_reviews: true
      )
      
      if result[:success]
        puts "✅ Data collection completed successfully!"
        puts "\n📊 Data Collection Statistics:"
        puts "  Repositories: #{result[:repositories_count]}"
        puts "  Pull Requests: #{result[:pull_requests_count]}"
        puts "  Reviews: #{result[:reviews_count]}"
        
        # Now collect user profiles
        puts "\n🔄 Collecting user profiles..."
        user_count = Github::UserService.fetch_all_users_from_contributors
        
        puts "\n📊 Final Statistics:"
        puts "  Repositories: #{result[:repositories_count]}"
        puts "  Pull Requests: #{result[:pull_requests_count]}"
        puts "  Reviews: #{result[:reviews_count]}"
        puts "  Users: #{User.count}"
        puts "  User profiles updated: #{user_count}"
        puts "  Complete profiles: #{User.where.not(name: [nil, '']).count}"
      else
        puts "❌ Data collection failed: #{result[:error]}"
        exit 1
      end
      
    rescue => e
      puts "❌ Comprehensive data collection failed: #{e.message}"
      puts "   Error type: #{e.class.name}"
      exit 1
    end
  end

  desc "Generate analytics report"
  task :analytics, [:organization, :date_range] => :environment do |task, args|
    organization = args[:organization] || 'vercel'
    date_range = args[:date_range] || '30_days'
    
    puts "📊 Generating analytics report"
    puts "   Organization: #{organization}"
    puts "   Date range: #{date_range}"
    
    begin
      analytics = Analytics::DataAnalysisService.generate_report(
        organization: organization,
        date_range: date_range
      )
      
      puts "✅ Analytics report generated successfully!"
      puts "\n📈 Overview:"
      puts "  Repositories: #{analytics[:overview][:total_repositories]}"
      puts "  Pull Requests: #{analytics[:overview][:total_pull_requests]}"
      puts "  Reviews: #{analytics[:overview][:total_reviews]}"
      puts "  Users: #{analytics[:overview][:total_users]}"
      puts "  Active Contributors: #{analytics[:overview][:active_contributors]}"
      
      puts "\n🔀 Pull Request Metrics:"
      puts "  Merge Rate: #{(analytics[:pull_request_analysis][:merge_rate] * 100).round(1)}%"
      puts "  Average Lifetime: #{analytics[:pull_request_analysis][:average_pr_lifetime]} days"
      puts "  PR Velocity: #{analytics[:pull_request_analysis][:pr_velocity]} PRs/day"
      
      puts "\n👥 User Metrics:"
      puts "  User Engagement: #{analytics[:user_analysis][:user_engagement]}%"
      puts "  Users with Profiles: #{analytics[:user_analysis][:users_with_profiles]}"
      
      puts "\n👀 Review Metrics:"
      puts "  Approval Rate: #{(analytics[:review_analysis][:approval_rate] * 100).round(1)}%"
      puts "  Review Coverage: #{analytics[:review_analysis][:review_quality_metrics][:review_coverage]}%"
      
      if analytics[:insights].any?
        puts "\n💡 Insights:"
        analytics[:insights].each do |insight|
          puts "  - #{insight[:type].upcase}: #{insight[:message]}"
        end
      end
      
    rescue => e
      puts "❌ Analytics generation failed: #{e.message}"
      puts "   Error type: #{e.class.name}"
      exit 1
    end
  end
end
