# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_super_admin!

  def show
    @facade = DashboardFacade.call(user: current_user).value
  end

  private

  def redirect_super_admin!
    redirect_to admin_root_path if current_user.super_admin?
  end
end
