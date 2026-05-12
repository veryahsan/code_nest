# frozen_string_literal: true

require "rails_helper"

RSpec.describe Teams::GenerateUniqueSlugService, type: :service do
  let(:org) { create(:organisation) }

  it "returns a parameterised base when nothing clashes" do
    result = described_class.call(organisation: org, base_name: "Engineering")
    expect(result).to be_success
    expect(result.value).to eq("engineering")
  end

  it "auto-suffixes when the slug exists in the same organisation" do
    create(:team, organisation: org, name: "Engineering", slug: "engineering")

    result = described_class.call(organisation: org, base_name: "Engineering")
    expect(result.value).to eq("engineering-1")
  end

  it "ignores collisions in other organisations" do
    other = create(:organisation)
    create(:team, organisation: other, name: "Engineering", slug: "engineering")

    result = described_class.call(organisation: org, base_name: "Engineering")
    expect(result.value).to eq("engineering")
  end

  it "respects except_id so an updating team can keep its slug" do
    team = create(:team, organisation: org, name: "Engineering", slug: "engineering")

    result = described_class.call(organisation: org, base_name: "Engineering", except_id: team.id)
    expect(result.value).to eq("engineering")
  end

  it "returns failure for a blank base name" do
    result = described_class.call(organisation: org, base_name: "")
    expect(result).to be_failure
  end
end
