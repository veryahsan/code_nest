# frozen_string_literal: true

module Api
  module V1
    class LanguagesController < BaseController
      def index
        render json: LanguageSerializer.new(Language.order(:name)).serializable_hash
      end

      def show
        language = Language.find(params[:id])
        render json: LanguageSerializer.new(language).serializable_hash
      end
    end
  end
end
