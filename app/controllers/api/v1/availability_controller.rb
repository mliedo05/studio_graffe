module Api
  module V1
    class AvailabilityController < ApplicationController
      def index
        stylist = User.stylists.find(params[:stylist_id])
        service = Service.find(params[:service_id])
        date    = Date.parse(params[:date])

        slots = AvailabilityService.slots_for(stylist: stylist, service: service, date: date)
        render json: { slots: slots }
      rescue ArgumentError
        render json: { error: "Fecha inválida." }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Recurso no encontrado." }, status: :not_found
      end
    end
  end
end
