# frozen_string_literal: true

class ProjectsController < ApplicationController
  include TenantScoped

  before_action :load_project, only: %i[show edit update destroy]
  before_action :build_project, only: %i[new create]

  def index
    authorize Project
    @pagy, @projects = pagy(
      policy_scope(current_organisation.projects)
        .includes(:team, :languages, :technologies)
        .order(:name),
    )
  end

  def show
    @languages = @project.languages.order(:name)
    @technologies = @project.technologies.order(:name)
    @documents = @project.project_documents.order(:title).limit(5)
    @remote_resources = @project.remote_resources.order(:name).limit(5)
  end

  def new
    @teams = current_organisation.teams.order(:name)
    @languages = Language.order(:name)
    @technologies = Technology.order(:name)
  end

  def create
    result = Projects::CreationFacade.call(
      organisation: current_organisation,
      attributes: project_params,
    )

    if result.success?
      redirect_to project_path(result.value), notice: "Project created."
    else
      @project = result.error
      @teams = current_organisation.teams.order(:name)
      @languages = Language.order(:name)
      @technologies = Technology.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @teams = current_organisation.teams.order(:name)
  end

  def update
    result = Projects::UpdateFacade.call(project: @project, attributes: project_params)

    if result.success?
      redirect_to project_path(@project), notice: "Project updated."
    else
      @project = result.error
      @teams = current_organisation.teams.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = Projects::DeletionService.call(project: @project)
    if result.success?
      redirect_to projects_path, notice: "Project deleted.", status: :see_other
    else
      redirect_to project_path(@project), alert: result.error, status: :see_other
    end
  end

  private

  def load_project
    @project = current_organisation.projects.find(params[:id])
    authorize @project
  end

  def build_project
    @project = current_organisation.projects.new
    authorize @project
  end

  def project_params
    params.require(:project).permit(
      :name, :slug, :description, :team_id,
      language_ids: [], technology_ids: [],
    )
  end
end
