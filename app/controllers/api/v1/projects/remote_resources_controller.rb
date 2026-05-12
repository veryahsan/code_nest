# frozen_string_literal: true

module Api
  module V1
    module Projects
      class RemoteResourcesController < BaseController
        before_action :require_api_organisation!
        before_action :load_project
        before_action :load_resource, only: %i[show update destroy]

        def index
          authorize RemoteResource
          render json: RemoteResourceSerializer.new(@project.remote_resources.order(:name)).serializable_hash
        end

        def show
          render json: RemoteResourceSerializer.new(@resource).serializable_hash
        end

        def create
          @resource = @project.remote_resources.new
          authorize @resource
          result = RemoteResources::UpsertService.call(remote_resource: @resource, attributes: resource_params)
          if result.success?
            render json: RemoteResourceSerializer.new(result.value).serializable_hash, status: :created
          else
            render_validation_errors!(result.error)
          end
        end

        def update
          authorize @resource
          result = RemoteResources::UpsertService.call(remote_resource: @resource, attributes: resource_params)
          if result.success?
            render json: RemoteResourceSerializer.new(@resource).serializable_hash
          else
            render_validation_errors!(result.error)
          end
        end

        def destroy
          authorize @resource
          @resource.destroy
          head :no_content
        end

        private

        def load_project
          @project = current_api_organisation.projects.find(params[:project_id])
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
  end
end
