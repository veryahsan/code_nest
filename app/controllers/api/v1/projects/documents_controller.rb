# frozen_string_literal: true

module Api
  module V1
    module Projects
      class DocumentsController < BaseController
        before_action :require_api_organisation!
        before_action :load_project
        before_action :load_document, only: %i[show update destroy]

        def index
          authorize ProjectDocument
          render json: ProjectDocumentSerializer.new(@project.project_documents.order(:title)).serializable_hash
        end

        def show
          render json: ProjectDocumentSerializer.new(@document).serializable_hash
        end

        def create
          @document = @project.project_documents.new
          authorize @document
          result = ProjectDocuments::UpsertService.call(document: @document, attributes: document_params)
          if result.success?
            render json: ProjectDocumentSerializer.new(result.value).serializable_hash, status: :created
          else
            render_validation_errors!(result.error)
          end
        end

        def update
          authorize @document
          result = ProjectDocuments::UpsertService.call(document: @document, attributes: document_params)
          if result.success?
            render json: ProjectDocumentSerializer.new(@document).serializable_hash
          else
            render_validation_errors!(result.error)
          end
        end

        def destroy
          authorize @document
          @document.destroy
          head :no_content
        end

        private

        def load_project
          @project = current_api_organisation.projects.find(params[:project_id])
        end

        def load_document
          @document = @project.project_documents.find(params[:id])
          authorize @document
        end

        def document_params
          params.require(:project_document).permit(:title, :url, :external_id, :metadata)
        end
      end
    end
  end
end
