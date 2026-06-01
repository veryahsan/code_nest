# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::CreationFacade, type: :facade do
  let(:org) { create(:organisation) }
  let(:lang) { create(:language) }
  let(:tech) { create(:technology) }

  it "creates a project with derived slug" do
    result = described_class.call(organisation: org, attributes: { name: "Phoenix" })
    expect(result).to be_success
    expect(result.value).to have_attributes(name: "Phoenix", slug: "phoenix", organisation: org)
  end

  it "auto-suffixes a clashing slug" do
    create(:project, organisation: org, name: "Phoenix", slug: "phoenix")
    result = described_class.call(organisation: org, attributes: { name: "Phoenix" })
    expect(result.value.slug).to eq("phoenix-1")
  end

  it "auto-creates the project's group conversation" do
    result = described_class.call(organisation: org, attributes: { name: "Phoenix" })
    expect(result.value.group_conversation).to be_present
    expect(result.value.group_conversation.title).to eq("Phoenix")
  end

  it "attaches languages and technologies in bulk" do
    result = described_class.call(
      organisation: org,
      attributes: { name: "Phoenix", language_ids: [ lang.id ], technology_ids: [ tech.id ] },
    )
    expect(result.value.languages).to include(lang)
    expect(result.value.technologies).to include(tech)
  end

  it "fails on a blank name" do
    result = described_class.call(organisation: org, attributes: { name: "" })
    expect(result).to be_failure
    expect(result.error.errors[:name]).to be_present
  end
end
