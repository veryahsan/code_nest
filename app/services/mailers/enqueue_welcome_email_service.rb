# frozen_string_literal: true

# Buffers a single welcome email for the given user onto the centralized email
# outbox at low priority. Invoked from User's after_create_commit so the model
# stays a one-line trigger.
#
# Super admins are provisioned out-of-band (seeds / Active Admin) and never
# receive the welcome email.
module Mailers
  class EnqueueWelcomeEmailService < ApplicationService
    def initialize(user:, outbox: Outbox)
      @user = user
      @outbox = outbox
    end

    def call
      return success(@user) if @user.super_admin?

      @outbox.enqueue(WelcomeMailer, :welcome, @user, priority: :low)
      success(@user)
    end
  end
end
