# Base service class for all application services
class ApplicationService
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  def call
    raise NotImplementedError, "Subclasses must implement #call"
  end

  private

  def log_info(message)
    Rails.logger.info "[#{self.class.name}] #{message}"
  end

  def log_error(message, error = nil)
    Rails.logger.error "[#{self.class.name}] #{message}"
    Rails.logger.error error.full_message if error
  end

  def log_debug(message)
    Rails.logger.debug "[#{self.class.name}] #{message}"
  end
end
