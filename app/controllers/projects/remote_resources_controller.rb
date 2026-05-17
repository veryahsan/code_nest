# frozen_string_literal: true

module Projects
  class RemoteResourcesController < ApplicationController
    include TenantScoped

    before_action :load_project
    before_action :load_resource, only: %i[show edit update destroy]

    def index
      authorize RemoteResource
      @pagy, @resources = pagy(@project.remote_resources.order(:name))
    end

    def show
      @show_credentials = policy(@resource).view_credentials?
    end

    def new
      @resource = @project.remote_resources.new
      authorize @resource
    end

    def create
      @resource = @project.remote_resources.new
      authorize @resource

      result = RemoteResources::UpsertService.call(remote_resource: @resource, attributes: resource_params)
      if result.success?
        redirect_to project_remote_resource_path(@project, result.value), notice: "Resource added."
      else
        @resource = result.error
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      result = RemoteResources::UpsertService.call(remote_resource: @resource, attributes: resource_params)
      if result.success?
        redirect_to project_remote_resource_path(@project, @resource), notice: "Resource updated."
      else
        @resource = result.error
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @resource.destroy
      redirect_to project_remote_resources_path(@project), notice: "Resource removed.", status: :see_other
    end

    private

    def load_project
      @project = current_organisation.projects.find(params[:project_id])
    end

    def load_resource
      @resource = @project.remote_resources.find(params[:id])
      authorize @resource
    end

    def resource_params
      params.require(:remote_resource).permit(:name, :kind, :url, :credentials_json)
    end
  end
end
