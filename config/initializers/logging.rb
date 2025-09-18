# Logging configuration for GitHub Scraper
Rails.application.configure do
  # Configure log level based on environment
  config.log_level = case Rails.env
                     when 'development'
                       :debug
                     when 'test'
                       :warn
                     when 'production'
                       :info
                     else
                       :info
                     end

  # Configure log format for better readability
  config.log_formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity.ljust(5)} #{progname}: #{msg}\n"
  end

  # Log to both file and console in development
  if Rails.env.development?
    config.logger = ActiveSupport::Logger.new(STDOUT)
  end
end
