module StylistPanel
  class DashboardController < BaseController
    def index
      month_range = Date.current.beginning_of_month..Date.current.end_of_month

      @items_this_month = AttendanceItem
        .joins(:attendance)
        .where(stylist_id: current_user.id, attendances: { attended_on: month_range })

      @total_sales_cents      = @items_this_month.sum(:price_cents)
      @total_commission_cents = @items_this_month.sum(:commission_cents)
      @items_count            = @items_this_month.count

      # Comisiones por servicio este mes
      @by_service = @items_this_month
        .group(:description)
        .select("description, COUNT(*) as count, SUM(commission_cents) as total_commission_cents")

      # Historial de últimos 5 meses
      @monthly_history = (0..4).map do |i|
        d     = i.months.ago
        range = d.beginning_of_month..d.end_of_month
        total = AttendanceItem.joins(:attendance)
                              .where(stylist_id: current_user.id, attendances: { attended_on: range })
                              .sum(:commission_cents)
        { month: d.strftime("%b %Y"), total_cents: total }
      end.reverse
    end
  end
end
