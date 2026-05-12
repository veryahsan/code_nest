# frozen_string_literal: true

module Projects
  class TechnologiesController < ApplicationController
    include TenantScoped

    before_action :load_project
    before_action :require_project_admin!

    def create
      technology = Technology.find(params[:technology_id])
      project_technology = @project.project_technologies.find_or_initialize_by(technology: technology)
      if project_technology.new_record? && !project_technology.save
        redirect_to project_path(@project), alert: project_technology.errors.full_messages.to_sentence, status: :see_other
      else
        redirect_to project_path(@project), notice: "#{technology.name} attached.", status: :see_other
      end
    end

    def destroy
      project_technology = @project.project_technologies.find(params[:id])
      name = project_technology.technology.name
      project_technology.destroy
      redirect_to project_path(@project), notice: "#{name} detached.", status: :see_other
    end

    private

    def load_project
      @project = current_organisation.projects.find(params[:project_id])
    end

    def require_project_admin!
      authorize @project, :update?
    end
  end
end
