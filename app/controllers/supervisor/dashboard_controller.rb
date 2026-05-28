module Supervisor
  class DashboardController < BaseController
    def index
      range = period_range

      @attendances_count    = Attendance.where(attended_on: range).count
      @total_sales_cents    = Attendance.where(attended_on: range).sum(:total_cents)
      @total_commissions_cents = AttendanceItem.joins(:attendance)
                                               .where(attendances: { attended_on: range })
                                               .sum(:commission_cents)

      # Ventas por día (para gráfico)
      @sales_by_day = Attendance.where(attended_on: range)
                                .group(:attended_on)
                                .sum(:total_cents)
                                .transform_keys { |d| d.strftime("%d/%m") }

      # Comisiones por estilista (para gráfico)
      @commissions_by_stylist = AttendanceItem
        .joins(:attendance, :stylist)
        .where(attendances: { attended_on: range })
        .group("users.first_name")
        .sum(:commission_cents)

      # Últimas atenciones
      @recent_attendances = Attendance.includes(:attendance_items, :attendance_payments)
                                      .where(attended_on: range)
                                      .ordered
                                      .limit(10)

      # Servicios más realizados (para gráfico)
      @services_chart = AttendanceItem
        .joins(:attendance, :service)
        .where(item_type: "service", attendances: { attended_on: range })
        .group("services.name")
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(10)
        .count

      # Stock crítico
      @critical_stock = Product.active.where("stock_quantity <= 3").order(:stock_quantity)
    end
  end
end
