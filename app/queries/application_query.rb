# frozen_string_literal: true

# Base class for AR query objects. Each subclass exposes a single `#resolve`
# method that returns an ActiveRecord::Relation, allowing further chaining.
class ApplicationQuery
  def self.call(...)
    new(...).resolve
  end

  def resolve
    raise NotImplementedError, "#{self.class} must implement #resolve"
  end
end
