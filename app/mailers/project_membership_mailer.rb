# frozen_string_literal: true

class ProjectMembershipMailer < ApplicationMailer
  def added(project_membership)
    @membership   = project_membership
    @user         = project_membership.user
    @project      = project_membership.project
    @organisation = @project.organisation
    @project_url  = project_url(@project)

    mail(
      to: @user.email,
      subject: "You've been added to #{@project.name}",
    )
  end
end
