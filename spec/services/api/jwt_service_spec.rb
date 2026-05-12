# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::JwtService do
  describe ".encode + .decode round-trip" do
    it "round-trips arbitrary payload data" do
      token = described_class.encode(sub: 123, email: "alice@example.com")
      payload = described_class.decode(token)

      expect(payload[:sub]).to eq(123)
      expect(payload[:email]).to eq("alice@example.com")
      expect(payload[:exp]).to be_present
      expect(payload[:iat]).to be_present
    end

    it "respects a custom TTL" do
      token = described_class.encode({ sub: 1 }, ttl: 60)
      payload = described_class.decode(token)
      expect(payload[:exp] - payload[:iat]).to eq(60)
    end
  end

  describe ".decode error cases" do
    it "raises DecodeError on a tampered signature" do
      token = described_class.encode(sub: 1)
      header, payload, signature = token.split(".")
      flipped = signature.reverse
      tampered = [ header, payload, flipped ].join(".")
      expect { described_class.decode(tampered) }.to raise_error(described_class::DecodeError)
    end

    it "raises DecodeError on an expired token" do
      token = described_class.encode({ sub: 1 }, ttl: -1)
      expect { described_class.decode(token) }.to raise_error(described_class::DecodeError, /expired/)
    end

    it "raises DecodeError on garbage" do
      expect { described_class.decode("nope") }.to raise_error(described_class::DecodeError)
    end
  end
end
