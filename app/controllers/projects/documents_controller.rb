# frozen_string_literal: true

module Projects
  class DocumentsController < ApplicationController
    include TenantScoped

    before_action :load_project
    before_action :load_document, only: %i[show edit update destroy]

    def index
      authorize ProjectDocument
      @pagy, @documents = pagy(@project.project_documents.order(:title))
    end

    def show; end

    def new
      @document = @project.project_documents.new
      authorize @document
    end

    def create
      @document = @project.project_documents.new
      authorize @document
      result = ProjectDocuments::UpsertService.call(document: @document, attributes: document_params)

      if result.success?
        redirect_to project_document_path(@project, result.value), notice: "Document added."
      else
        @document = result.error
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      result = ProjectDocuments::UpsertService.call(document: @document, attributes: document_params)
      if result.success?
        redirect_to project_document_path(@project, @document), notice: "Document updated."
      else
        @document = result.error
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @document.destroy
      redirect_to project_documents_path(@project), notice: "Document removed.", status: :see_other
    end

    private

    def load_project
      @project = current_organisation.projects.find(params[:project_id])
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
