# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationsChannel, type: :channel do
  let(:user) { create(:user) }

  it "streams for the authenticated current user" do
    stub_connection current_user: user
    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(user)
  end

  it "stops streaming on unsubscribe" do
    stub_connection current_user: user
    subscribe
    unsubscribe

    expect(subscription.streams).to be_empty
  end
end
