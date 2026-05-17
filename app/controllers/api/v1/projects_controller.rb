# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < BaseController
      before_action :require_api_organisation!
      before_action :load_project, only: %i[show update destroy]

      def index
        authorize Project
        @pagy, projects = pagy(
          policy_scope(current_api_organisation.projects)
            .includes(:team, :languages, :technologies)
            .order(:name),
        )
        render json: ProjectSerializer.new(
          projects,
          meta:  pagy_meta(@pagy),
          links: pagy_links(@pagy),
        ).serializable_hash
      end

      def show
        render json: ProjectSerializer.new(@project).serializable_hash
      end

      def create
        authorize Project
        result = ::Projects::CreationFacade.call(organisation: current_api_organisation, attributes: project_params)
        if result.success?
          render json: ProjectSerializer.new(result.value).serializable_hash, status: :created
        else
          render_validation_errors!(result.error)
        end
      end

      def update
        authorize @project
        result = ::Projects::UpdateFacade.call(project: @project, attributes: project_params)
        if result.success?
          render json: ProjectSerializer.new(@project).serializable_hash
        else
          render_validation_errors!(result.error)
        end
      end

      def destroy
        authorize @project
        result = ::Projects::DeletionService.call(project: @project)
        if result.success?
          head :no_content
        else
          render_error!(:unprocessable_entity, result.error)
        end
      end

      private

      def load_project
        @project = current_api_organisation.projects.find(params[:id])
        authorize @project
      end

      def project_params
        params.require(:project).permit(
          :name, :slug, :description, :team_id,
          language_ids: [], technology_ids: [],
        )
      end
    end
  end
end
