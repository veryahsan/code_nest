# frozen_string_literal: true

module Api
  module V1
    class TechnologiesController < BaseController
      def index
        render json: TechnologySerializer.new(Technology.order(:name)).serializable_hash
      end

      def show
        tech = Technology.find(params[:id])
        render json: TechnologySerializer.new(tech).serializable_hash
      end
    end
  end
end
