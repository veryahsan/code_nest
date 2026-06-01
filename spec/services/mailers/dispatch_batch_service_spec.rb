# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mailers::DispatchBatchService, type: :service do
  let(:outbox) { Mailers::Outbox.new }

  # Creating users triggers the welcome-email enqueue (after_create_commit);
  # stub it so only the payloads each example sets up are in the outbox.
  before do
    ActionMailer::Base.deliveries.clear
    allow(Mailers::EnqueueWelcomeEmailService).to receive(:call)
  end

  def stub_failing_delivery
    mail = instance_double(ActionMailer::MessageDelivery)
    allow(WelcomeMailer).to receive(:welcome).and_return(mail)
    allow(mail).to receive(:deliver_now).and_raise(StandardError, "smtp down")
  end

  it "delivers queued email and reports the count sent" do
    outbox.enqueue(WelcomeMailer, :welcome, create(:user), priority: :low)

    result = described_class.call(outbox: outbox)

    expect(result).to be_success
    expect(result.value).to eq(1)
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it "prefers higher-priority tiers when the budget is constrained" do
    outbox.enqueue(WelcomeMailer, :welcome, create(:user), priority: :high)
    outbox.enqueue(WelcomeMailer, :welcome, create(:user), priority: :low)
    limiter = instance_double(Mailers::RateLimiter, acquire: 1)

    described_class.call(outbox: outbox, rate_limiter: limiter)

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(outbox.size(:high)).to eq(0)
    expect(outbox.size(:low)).to eq(1)
  end

  it "re-enqueues a transient failure with a bumped retry counter" do
    outbox.enqueue(WelcomeMailer, :welcome, create(:user), priority: :default)
    stub_failing_delivery

    described_class.call(outbox: outbox)

    expect(outbox.size(:default)).to eq(1)
    expect(outbox.pop(:default, 1).first["retries"]).to eq(1)
  end

  it "dead-letters and reports a payload that has exhausted its retries" do
    user = create(:user)
    payload = {
      "mailer" => "WelcomeMailer",
      "action" => "welcome",
      "args" => ActiveJob::Arguments.serialize([ user ]),
      "retries" => Mailers::Outbox::MAX_RETRIES
    }
    REDIS_POOL.with { |redis| redis.rpush("mailer:outbox:default", JSON.generate(payload)) }
    stub_failing_delivery
    allow(Sentry).to receive(:capture_exception)

    described_class.call(outbox: outbox)

    expect(outbox.size(:default)).to eq(0)
    expect(REDIS_POOL.with { |redis| redis.llen("mailer:outbox:dead") }).to eq(1)
    expect(Sentry).to have_received(:capture_exception)
  end

  it "drops a payload whose record no longer exists" do
    user = create(:user)
    outbox.enqueue(WelcomeMailer, :welcome, user, priority: :default)
    user.destroy

    described_class.call(outbox: outbox)

    expect(outbox.size(:default)).to eq(0)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "does nothing while a global backoff is active" do
    outbox.enqueue(WelcomeMailer, :welcome, create(:user), priority: :high)
    REDIS_POOL.with { |redis| redis.set("mailer:paused_until", Time.now.to_f + 60) }

    result = described_class.call(outbox: outbox)

    expect(result.value).to eq(0)
    expect(ActionMailer::Base.deliveries).to be_empty
    expect(outbox.size(:high)).to eq(1)
  end

  it "engages a global backoff when an entire tick fails" do
    outbox.enqueue(WelcomeMailer, :welcome, create(:user), priority: :default)
    stub_failing_delivery

    described_class.call(outbox: outbox)

    paused_until = REDIS_POOL.with { |redis| redis.get("mailer:paused_until") }
    expect(paused_until.to_f).to be > Time.now.to_f
  end
end
