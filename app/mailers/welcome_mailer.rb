# frozen_string_literal: true

class WelcomeMailer < ApplicationMailer
  def welcome(user)
    @user = user
    @email = user.email
    @login_url = new_user_session_url

    mail(
      to: user.email,
      subject: "Welcome to Code Nest",
    )
  end
end
