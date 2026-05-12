# frozen_string_literal: true

module Api
  module V1
    module Projects
      class TechnologiesController < BaseController
        before_action :require_api_organisation!
        before_action :load_project

        def index
          render json: TechnologySerializer.new(@project.technologies.order(:name)).serializable_hash
        end

        def create
          authorize @project, :update?
          technology = Technology.find(params.dig(:technology, :id) || params[:technology_id])
          link = @project.project_technologies.find_or_initialize_by(technology: technology)

          if link.new_record? && !link.save
            render_validation_errors!(link)
          else
            render json: TechnologySerializer.new(technology).serializable_hash, status: :created
          end
        end

        def destroy
          authorize @project, :update?
          link = @project.project_technologies.find(params[:id])
          link.destroy
          head :no_content
        end

        private

        def load_project
          @project = current_api_organisation.projects.find(params[:project_id])
        end
      end
    end
  end
end
