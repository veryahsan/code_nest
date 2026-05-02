# frozen_string_literal: true

# Base class for all facades.
#
# A facade orchestrates several service objects to deliver a complete
# user-facing flow (e.g. ProjectCreationFacade, DocumentationFacade,
# IntegrationFacade, NotificationFacade).
#
# Controllers should call facades, not individual services.
class ApplicationFacade
  Result = ApplicationService::Result

  def self.call(...)
    new(...).call
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  def success(value = nil)
    Result.new(success: true, value: value, error: nil)
  end

  def failure(error)
    Result.new(success: false, value: nil, error: error)
  end
end
