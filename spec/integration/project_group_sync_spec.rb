# frozen_string_literal: true

require "rails_helper"

# End-to-end: creating a project provisions its group conversation, and
# project membership changes keep the group roster in sync.
RSpec.describe "Project group conversation sync", type: :model do
  let(:org) { create(:organisation) }

  it "auto-creates a group conversation mirroring project membership" do
    project = create(:project, organisation: org, name: "Phoenix")
    group = project.group_conversation

    expect(group).to be_present
    expect(group).to be_group
    expect(group.participants).to be_empty

    alice = create(:user, organisation: org)
    bob = create(:user, organisation: org)

    create(:project_membership, project: project, user: alice)
    create(:project_membership, project: project, user: bob)

    expect(group.reload.participants).to contain_exactly(alice, bob)

    project.project_memberships.find_by(user: bob).destroy

    expect(group.reload.participants).to contain_exactly(alice)
  end

  it "tears down the group conversation when the project is destroyed" do
    project = create(:project, organisation: org)
    group_id = project.group_conversation.id

    project.destroy

    expect(Conversation.exists?(group_id)).to be false
  end
end
