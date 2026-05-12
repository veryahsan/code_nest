# frozen_string_literal: true

require "rails_helper"

RSpec.describe Teams::CreationFacade, type: :facade do
  let(:org) { create(:organisation) }

  it "creates the team and derives a unique slug from the name" do
    result = described_class.call(organisation: org, attributes: { name: "Engineering" })

    expect(result).to be_success
    expect(result.value).to be_persisted
    expect(result.value).to have_attributes(name: "Engineering", slug: "engineering")
    expect(result.value.organisation).to eq(org)
  end

  it "respects an explicit slug" do
    result = described_class.call(organisation: org, attributes: { name: "Engineering", slug: "eng" })
    expect(result.value.slug).to eq("eng")
  end

  it "auto-suffixes a clashing slug within the same organisation" do
    create(:team, organisation: org, slug: "eng")
    result = described_class.call(organisation: org, attributes: { name: "Engineering", slug: "eng" })
    expect(result.value.slug).to eq("eng-1")
  end

  it "fails with errors when the name is blank" do
    result = described_class.call(organisation: org, attributes: { name: "" })
    expect(result).to be_failure
    expect(result.error).to be_a(Team)
    expect(result.error.errors[:name]).to be_present
  end
end
