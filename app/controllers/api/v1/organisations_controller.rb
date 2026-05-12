# frozen_string_literal: true

module Api
  module V1
    class OrganisationsController < BaseController
      before_action :require_api_organisation!
      before_action :load_organisation

      def show
        authorize @organisation, :show?
        render json: OrganisationSerializer.new(@organisation).serializable_hash
      end

      def update
        authorize @organisation, :update?
        result = Organisations::UpdateFacade.call(organisation: @organisation, attributes: organisation_params)
        if result.success?
          render json: OrganisationSerializer.new(result.value).serializable_hash
        else
          render_validation_errors!(result.error)
        end
      end

      def destroy
        authorize @organisation, :destroy?
        result = Organisations::DeletionService.call(organisation: @organisation)
        if result.success?
          head :no_content
        else
          render_error!(:unprocessable_entity, result.error)
        end
      end

      private

      def load_organisation
        @organisation = current_api_organisation
      end

      def organisation_params
        params.require(:organisation).permit(:name, :slug)
      end
    end
  end
end
