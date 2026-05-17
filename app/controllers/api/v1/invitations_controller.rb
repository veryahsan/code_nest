# frozen_string_literal: true

module Api
  module V1
    class InvitationsController < BaseController
      skip_before_action :authenticate_api_user!, only: %i[accept]
      before_action :require_api_organisation!, except: %i[accept]
      before_action :load_invitation, only: %i[show destroy]

      def index
        authorize Invitation
        @pagy, invitations = pagy(
          policy_scope(current_api_organisation.invitations).order(created_at: :desc),
        )
        render json: InvitationSerializer.new(
          invitations,
          meta:  pagy_meta(@pagy),
          links: pagy_links(@pagy),
        ).serializable_hash
      end

      def show
        render json: InvitationSerializer.new(@invitation).serializable_hash
      end

      def create
        authorize Invitation
        result = Invitations::CreationFacade.call(
          organisation: current_api_organisation,
          inviter: current_api_user,
          attributes: invitation_params,
        )
        if result.success?
          render json: InvitationSerializer.new(result.value).serializable_hash, status: :created
        else
          render_validation_errors!(result.error)
        end
      end

      def destroy
        authorize @invitation
        result = Invitations::RevokeService.call(invitation: @invitation)
        if result.success?
          head :no_content
        else
          render_error!(:unprocessable_entity, result.error)
        end
      end

      def accept
        token = params.dig(:invitation_acceptance, :token) || params[:token]
        password = params.dig(:invitation_acceptance, :password) || params[:password]
        return render_error!(:bad_request, "token is required") if token.blank?

        result = Invitations::AcceptFacade.call(token: token, password: password)
        if result.success?
          new_token = Api::JwtService.encode(sub: result.value.id, email: result.value.email)
          render json: {
            data: {
              token: new_token,
              expires_in: Api::JwtService::DEFAULT_TTL,
              user: UserSerializer.new(result.value).serializable_hash[:data]
            }
          }, status: :ok
        else
          render_error!(:unprocessable_entity, result.error)
        end
      end

      private

      def load_invitation
        @invitation = current_api_organisation.invitations.find(params[:id])
        authorize @invitation
      end

      def invitation_params
        params.require(:invitation).permit(:email, :org_role, :expires_at)
      end
    end
  end
end
