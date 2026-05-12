# frozen_string_literal: true

module Api
  module V1
    class TeamsController < BaseController
      before_action :require_api_organisation!
      before_action :load_team, only: %i[show update destroy]

      def index
        authorize Team
        teams = policy_scope(current_api_organisation.teams).order(:name)
        render json: TeamSerializer.new(teams).serializable_hash
      end

      def show
        render json: TeamSerializer.new(@team).serializable_hash
      end

      def create
        authorize Team
        result = ::Teams::CreationFacade.call(organisation: current_api_organisation, attributes: team_params)
        if result.success?
          render json: TeamSerializer.new(result.value).serializable_hash, status: :created
        else
          render_validation_errors!(result.error)
        end
      end

      def update
        authorize @team
        result = ::Teams::UpdateFacade.call(team: @team, attributes: team_params)
        if result.success?
          render json: TeamSerializer.new(@team).serializable_hash
        else
          render_validation_errors!(result.error)
        end
      end

      def destroy
        authorize @team
        result = ::Teams::DeletionService.call(team: @team)
        if result.success?
          head :no_content
        else
          render_error!(:unprocessable_entity, result.error)
        end
      end

      private

      def load_team
        @team = current_api_organisation.teams.find(params[:id])
        authorize @team
      end

      def team_params
        params.require(:team).permit(:name, :slug)
      end
    end
  end
end
