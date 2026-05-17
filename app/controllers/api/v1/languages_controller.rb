# frozen_string_literal: true

module Api
  module V1
    class LanguagesController < BaseController
      def index
        @pagy, languages = pagy(Language.order(:name))
        render json: LanguageSerializer.new(
          languages,
          meta:  pagy_meta(@pagy),
          links: pagy_links(@pagy),
        ).serializable_hash
      end

      def show
        language = Language.find(params[:id])
        render json: LanguageSerializer.new(language).serializable_hash
      end
    end
  end
end
