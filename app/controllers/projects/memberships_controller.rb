# frozen_string_literal: true

# Adds and removes a User from a Project. Always nested under a project
# loaded from current_organisation, so cross-tenant joins are impossible
# by construction. Adding/removing a member also syncs the project's group
# conversation (handled by ProjectMembership callbacks).
module Projects
  class MembershipsController < ApplicationController
    include TenantScoped

    before_action :load_project

    def create
      user = current_organisation.users.find_by(id: params[:user_id])
      membership = @project.project_memberships.new(user: user)
      authorize membership

      if user.nil?
        redirect_to project_path(@project), alert: "Pick a user from your organisation."
      elsif membership.save
        redirect_to project_path(@project), notice: "#{user.email} added to #{@project.name}."
      else
        redirect_to project_path(@project), alert: membership.errors.full_messages.to_sentence
      end
    end

    def destroy
      membership = @project.project_memberships.find(params[:id])
      authorize membership
      email = membership.user.email
      membership.destroy
      redirect_to project_path(@project), notice: "#{email} removed from #{@project.name}.", status: :see_other
    end

    def promote_lead
      membership = @project.project_memberships.find(params[:id])
      authorize membership, :promote_lead?

      ProjectMembership.transaction do
        @project.project_memberships.leads.update_all(lead: false)
        membership.update!(lead: true)
      end

      redirect_to project_path(@project), notice: "#{membership.user.email} is now project lead."
    end

    private

    def load_project
      @project = current_organisation.projects.find(params[:project_id])
    end
  end
end
