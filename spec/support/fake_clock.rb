# frozen_string_literal: true

# Controllable stand-in for Time, used to advance the rate limiter's window
# deterministically in specs. `now` returns the current (mutable) epoch float.
class FakeClock
  attr_accessor :time

  def initialize(time)
    @time = time
  end

  def now
    @time
  end
end
