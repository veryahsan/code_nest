# frozen_string_literal: true

require "rails_helper"

RSpec.describe IssuePolicy, type: :policy do
  let(:org)   { create(:organisation) }
  let(:project) { create(:project, organisation: org) }
  let(:issue) { create(:issue, project: project) }

  let(:admin)     { create(:user, :organisation_admin, organisation: org) }
  let(:lead)      { create(:user, organisation: org) }
  let(:member)    { create(:user, organisation: org) }
  let(:outsider)  { create(:user, organisation: create(:organisation)) }

  before do
    create(:project_membership, project: project, user: lead, lead: true)
    create(:project_membership, project: project, user: member, lead: false)
  end

  describe "viewing" do
    it "allows project members to index and show" do
      expect(described_class.new(member, issue)).to permit_actions(%i[index show])
    end

    it "allows org admins to index and show" do
      expect(described_class.new(admin, issue)).to permit_actions(%i[index show])
    end

    it "forbids users outside the project" do
      other = create(:user, organisation: org)
      expect(described_class.new(other, issue)).to forbid_actions(%i[index show])
    end
  end

  describe "mutations" do
    it "allows the project lead to create, update, and destroy" do
      expect(described_class.new(lead, issue)).to permit_actions(%i[create update destroy])
    end

    it "forbids regular project members from mutating" do
      expect(described_class.new(member, issue)).to forbid_actions(%i[create update destroy])
    end

    it "forbids org admins who are not project lead" do
      expect(described_class.new(admin, issue)).to forbid_actions(%i[create update destroy])
    end
  end
end
