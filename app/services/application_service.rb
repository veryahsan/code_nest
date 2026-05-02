# frozen_string_literal: true

# Base class for all service objects.
#
# A service object encapsulates a single, focused piece of business logic
# (e.g. CreateProjectService, AssignEmployeeService, SyncGoogleDocService).
#
# Conventions:
#   * One public method: `#call`.
#   * Returns a `Result` exposing `success?`, `failure?`, `value`, `error`.
#   * Service is callable via `MyService.call(args)` (delegates to `new(args).call`).
#   * No HTTP, no rendering, no controller concerns.
class ApplicationService
  Result = Struct.new(:success, :value, :error, keyword_init: true) do
    def success? = success
    def failure? = !success
  end

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
