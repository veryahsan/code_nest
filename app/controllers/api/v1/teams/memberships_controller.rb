# frozen_string_literal: true

module Api
  module V1
    module Teams
      class MembershipsController < BaseController
        before_action :require_api_organisation!
        before_action :load_team

        def index
          # `order(:created_at)` gives pagy a deterministic ordering — without
          # it, postgres may shuffle rows across pages.
          @pagy, memberships = pagy(@team.team_memberships.order(:created_at))
          render json: TeamMembershipSerializer.new(
            memberships,
            meta:  pagy_meta(@pagy),
            links: pagy_links(@pagy),
          ).serializable_hash
        end

        def create
          user = current_api_organisation.users.find_by(id: params.dig(:membership, :user_id))
          membership = @team.team_memberships.new(user: user)
          authorize membership

          if user.nil?
            return render_error!(:unprocessable_entity, "user must belong to your organisation")
          end

          if membership.save
            render json: TeamMembershipSerializer.new(membership).serializable_hash, status: :created
          else
            render_validation_errors!(membership)
          end
        end

        def destroy
          membership = @team.team_memberships.find(params[:id])
          authorize membership
          membership.destroy
          head :no_content
        end

        private

        def load_team
          @team = current_api_organisation.teams.find(params[:team_id])
        end
      end
    end
  end
end
