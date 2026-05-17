# frozen_string_literal: true

module Api
  module V1
    class TechnologiesController < BaseController
      def index
        @pagy, technologies = pagy(Technology.order(:name))
        render json: TechnologySerializer.new(
          technologies,
          meta:  pagy_meta(@pagy),
          links: pagy_links(@pagy),
        ).serializable_hash
      end

      def show
        tech = Technology.find(params[:id])
        render json: TechnologySerializer.new(tech).serializable_hash
      end
    end
  end
end
