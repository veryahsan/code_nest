# frozen_string_literal: true

module Api
  module V1
    module Projects
      class LanguagesController < BaseController
        before_action :require_api_organisation!
        before_action :load_project

        def index
          render json: LanguageSerializer.new(@project.languages.order(:name)).serializable_hash
        end

        def create
          authorize @project, :update?
          language = Language.find(params.dig(:language, :id) || params[:language_id])
          link = @project.project_languages.find_or_initialize_by(language: language)

          if link.new_record? && !link.save
            render_validation_errors!(link)
          else
            render json: LanguageSerializer.new(language).serializable_hash, status: :created
          end
        end

        def destroy
          authorize @project, :update?
          link = @project.project_languages.find(params[:id])
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
