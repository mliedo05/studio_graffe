module Supervisor
  class ClientsController < BaseController
    def index
      @q = params[:q].to_s.strip
      clients = User.clients.order(:first_name, :last_name)
      clients = clients.where(
        "first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q OR phone ILIKE :q",
        q: "%#{@q}%"
      ) if @q.present?
      @clients = clients
    end

    def show
      @client = User.clients.find(params[:id])
      @attendances = @client.attendances_as_client.includes(:attendance_items, :attendance_payments).ordered
      @orders = @client.orders.where(status: %w[paid shipped delivered]).order(created_at: :desc)
      @total_spent_attendances = @attendances.sum(:total_cents)
      @total_spent_orders      = @orders.sum(:total_cents)
    rescue ActiveRecord::RecordNotFound
      render plain: "No encontrado", status: :not_found
    end
  end
end
