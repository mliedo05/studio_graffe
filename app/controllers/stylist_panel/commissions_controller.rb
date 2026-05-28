module StylistPanel
  class CommissionsController < BaseController
    def index
      @month = params[:month].present? ? Date.parse("#{params[:month]}-01") : Date.current
      range  = @month.beginning_of_month..@month.end_of_month

      @items = AttendanceItem
        .joins(:attendance)
        .includes(:attendance, :service, :product)
        .where(stylist_id: current_user.id, attendances: { attended_on: range })
        .order("attendances.attended_on DESC, attendances.number DESC")

      @total_sales_cents      = @items.sum(:price_cents)
      @total_commission_cents = @items.sum(:commission_cents)

      @pagy, @items = pagy(@items, items: 30)
    end
  end
end
