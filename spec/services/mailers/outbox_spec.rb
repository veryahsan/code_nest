# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::Outbox, type: :service do
  subject(:outbox) { described_class.new }

  it "routes an enqueue to the requested priority tier" do
    outbox.enqueue(WelcomeMailer, :welcome, 1, priority: :low)

    expect(outbox.size(:low)).to eq(1)
    expect(outbox.size(:high)).to eq(0)
    expect(outbox.size(:default)).to eq(0)
  end

  it "falls back to the default tier for an unknown priority" do
    outbox.enqueue(WelcomeMailer, :welcome, 1, priority: :bogus)

    expect(outbox.size(:default)).to eq(1)
  end

  it "round-trips ActiveRecord arguments through GlobalID" do
    user = create(:user)
    outbox.enqueue(WelcomeMailer, :welcome, user, priority: :high)

    payload = outbox.pop(:high, 10).first
    expect(payload["mailer"]).to eq("WelcomeMailer")
    expect(payload["action"]).to eq("welcome")
    expect(ActiveJob::Arguments.deserialize(payload["args"])).to eq([ user ])
  end

  it "pops FIFO within a tier" do
    outbox.enqueue(WelcomeMailer, :welcome, 1, priority: :default)
    outbox.enqueue(WelcomeMailer, :welcome, 2, priority: :default)

    first, second = outbox.pop(:default, 2)
    expect(ActiveJob::Arguments.deserialize(first["args"])).to eq([ 1 ])
    expect(ActiveJob::Arguments.deserialize(second["args"])).to eq([ 2 ])
  end

  it "bumps the retry counter on requeue and parks dead letters" do
    outbox.enqueue(WelcomeMailer, :welcome, 1, priority: :default)
    payload = outbox.pop(:default, 1).first

    outbox.requeue(:default, payload)
    requeued = outbox.pop(:default, 1).first
    expect(requeued["retries"]).to eq(1)

    outbox.dead_letter(requeued)
    dead = REDIS_POOL.with { |redis| redis.llen("mailer:outbox:dead") }
    expect(dead).to eq(1)
  end
end
