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
end
