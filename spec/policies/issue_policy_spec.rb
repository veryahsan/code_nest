# frozen_string_literal: true

require "rails_helper"

RSpec.describe IssuePolicy, type: :policy do
  let(:org)   { create(:organisation) }
  let(:team)  { create(:team, organisation: org) }
  let(:project) { create(:project, organisation: org, team: team) }
  let(:issue) { create(:issue, project: project) }

  let(:admin)     { create(:user, :organisation_admin, organisation: org) }
  let(:lead)      { create(:user, organisation: org) }
  let(:member)    { create(:user, organisation: org) }
  let(:outsider)  { create(:user, organisation: create(:organisation)) }

  before do
    create(:team_membership, team: team, user: lead, lead: true)
    create(:team_membership, team: team, user: member, lead: false)
  end

  describe "viewing" do
    it "allows team members to index and show" do
      expect(described_class.new(member, issue)).to permit_actions(%i[index show])
    end

    it "allows org admins to index and show" do
      expect(described_class.new(admin, issue)).to permit_actions(%i[index show])
    end

    it "forbids users outside the team" do
      other = create(:user, organisation: org)
      expect(described_class.new(other, issue)).to forbid_actions(%i[index show])
    end
  end

  describe "mutations" do
    it "allows the team lead to create, update, and destroy" do
      expect(described_class.new(lead, issue)).to permit_actions(%i[create update destroy])
    end

    it "forbids regular team members from mutating" do
      expect(described_class.new(member, issue)).to forbid_actions(%i[create update destroy])
    end

    it "forbids org admins who are not team lead" do
      expect(described_class.new(admin, issue)).to forbid_actions(%i[create update destroy])
    end
  end
end
