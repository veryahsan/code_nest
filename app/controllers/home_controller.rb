# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    return unless user_signed_in?

    if current_user.super_admin?
      redirect_to admin_root_path
    elsif current_user.organisation.present?
      redirect_to dashboard_path
    end
  end
end
