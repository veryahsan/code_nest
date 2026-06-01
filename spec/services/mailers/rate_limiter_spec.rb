# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::RateLimiter, type: :service do
  let(:clock) { FakeClock.new(1_000.0) }

  it "grants up to the limit within a window" do
    limiter = described_class.new(limit: 3, window: 5, clock: clock)

    expect(limiter.acquire(2)).to eq(2)
    expect(limiter.acquire(5)).to eq(1)
    expect(limiter.acquire(1)).to eq(0)
  end

  it "never grants more than requested" do
    limiter = described_class.new(limit: 100, window: 5, clock: clock)

    expect(limiter.acquire(4)).to eq(4)
  end

  it "refills once the window has elapsed" do
    limiter = described_class.new(limit: 2, window: 5, clock: clock)
    expect(limiter.acquire(2)).to eq(2)
    expect(limiter.acquire(1)).to eq(0)

    clock.time = 1_006.0

    expect(limiter.acquire(2)).to eq(2)
  end

  it "returns zero for non-positive requests" do
    limiter = described_class.new(limit: 5, window: 5, clock: clock)

    expect(limiter.acquire(0)).to eq(0)
    expect(limiter.acquire(-3)).to eq(0)
  end
end
