# frozen_string_literal: true

module Projects
  class LanguagesController < ApplicationController
    include TenantScoped

    before_action :load_project
    before_action :require_project_admin!

    def create
      language = Language.find(params[:language_id])
      project_language = @project.project_languages.find_or_initialize_by(language: language)
      if project_language.new_record? && !project_language.save
        redirect_to project_path(@project), alert: project_language.errors.full_messages.to_sentence, status: :see_other
      else
        redirect_to project_path(@project), notice: "#{language.name} attached.", status: :see_other
      end
    end

    def destroy
      project_language = @project.project_languages.find(params[:id])
      name = project_language.language.name
      project_language.destroy
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
