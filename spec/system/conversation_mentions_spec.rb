# frozen_string_literal: true

require "rails_helper"

# Exercises the Lexxy @-mention prompt end to end in a real browser. Tagged :js
# so it runs under headless Chrome (see spec/rails_helper.rb); skipped by the
# default rack_test runner since the prompt is JavaScript-driven.
RSpec.describe "Conversation @mentions", :js, type: :system do
  include Warden::Test::Helpers

  let(:org) { create(:organisation) }
  let(:author) { create(:user, organisation: org) }
  let(:teammate) { create(:user, organisation: org) }
  let(:conversation) { create(:conversation, organisation: org) }

  before do
    create(:employee, user: author, organisation: org, handle: "author")
    create(:employee, user: teammate, organisation: org, handle: "casey", display_name: "Casey Jones")
    conversation.add_participant(author)
    conversation.add_participant(teammate)
    login_as(author, scope: :user)
  end

  after { Warden.test_reset! }

  it "inserts a mention via the @ prompt, sends it, and persists the mentioned user" do
    visit conversation_path(conversation)

    editor = find("lexxy-editor")
    editor.click
    editor.send_keys("hi @casey")

    # The prompt menu opens; Enter picks the highlighted suggestion.
    find(".lexxy-prompt-menu--visible", wait: 5)
    editor.send_keys(:enter)

    # A second Enter (menu now closed) sends the message.
    editor.send_keys(:enter)

    within("[data-conversation-target='list']") do
      expect(page).to have_css(".mention", text: "@casey", wait: 5)
    end

    expect(conversation.messages.last.mentioned_users).to include(teammate)
  end
end
