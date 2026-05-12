# frozen_string_literal: true

# Adds and removes a User from a Team. Always nested under a team
# loaded from current_organisation, so cross-tenant joins are
# impossible by construction.
module Teams
  class MembershipsController < ApplicationController
    include TenantScoped

    before_action :load_team

    def create
      user = current_organisation.users.find_by(id: params[:user_id])
      membership = @team.team_memberships.new(user: user)
      authorize membership

      if user.nil?
        redirect_to team_path(@team), alert: "Pick a user from your organisation."
      elsif membership.save
        redirect_to team_path(@team), notice: "#{user.email} added to #{@team.name}."
      else
        redirect_to team_path(@team), alert: membership.errors.full_messages.to_sentence
      end
    end

    def destroy
      membership = @team.team_memberships.find(params[:id])
      authorize membership
      email = membership.user.email
      membership.destroy
      redirect_to team_path(@team), notice: "#{email} removed from #{@team.name}.", status: :see_other
    end

    private

    def load_team
      @team = current_organisation.teams.find(params[:team_id])
    end
  end
end
