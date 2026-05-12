# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::GenerateUniqueSlugService, type: :service do
  let(:org) { create(:organisation) }

  it "returns parameterised base when nothing clashes" do
    expect(described_class.call(organisation: org, base_name: "Phoenix").value).to eq("phoenix")
  end

  it "auto-suffixes when slug exists in same org" do
    create(:project, organisation: org, slug: "phoenix")
    expect(described_class.call(organisation: org, base_name: "Phoenix").value).to eq("phoenix-1")
  end

  it "ignores collisions in another org" do
    other = create(:organisation)
    create(:project, organisation: other, slug: "phoenix")
    expect(described_class.call(organisation: org, base_name: "Phoenix").value).to eq("phoenix")
  end

  it "respects except_id" do
    project = create(:project, organisation: org, slug: "phoenix")
    expect(described_class.call(organisation: org, base_name: "Phoenix", except_id: project.id).value).to eq("phoenix")
  end

  it "fails on blank base" do
    expect(described_class.call(organisation: org, base_name: "")).to be_failure
  end
end
