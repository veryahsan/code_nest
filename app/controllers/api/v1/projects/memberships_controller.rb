# frozen_string_literal: true

module Api
  module V1
    module Projects
      class MembershipsController < BaseController
        before_action :require_api_organisation!
        before_action :load_project

        def index
          @pagy, memberships = pagy(@project.project_memberships.order(:created_at))
          render json: ProjectMembershipSerializer.new(
            memberships,
            meta:  pagy_meta(@pagy),
            links: pagy_links(@pagy),
          ).serializable_hash
        end

        def create
          user = current_api_organisation.users.find_by(id: params.dig(:membership, :user_id))
          membership = @project.project_memberships.new(user: user)
          authorize membership

          if user.nil?
            return render_error!(:unprocessable_entity, "user must belong to your organisation")
          end

          if membership.save
            render json: ProjectMembershipSerializer.new(membership).serializable_hash, status: :created
          else
            render_validation_errors!(membership)
          end
        end

        def destroy
          membership = @project.project_memberships.find(params[:id])
          authorize membership
          membership.destroy
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
