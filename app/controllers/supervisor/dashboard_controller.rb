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

      # Una sola consulta agrupa por servicio → frecuencia + ingresos
      services_raw = AttendanceItem
        .joins(:attendance, :service)
        .where(item_type: "service", attendances: { attended_on: range })
        .group("services.name")
        .select(
          "services.name AS service_name",
          "COUNT(*) AS times_done",
          "SUM(attendance_items.price_cents) AS total_revenue"
        )

      @services_frequency = services_raw.sort_by { |r| -r.times_done.to_i }
                                        .first(10)
                                        .to_h { |r| [ r.service_name, r.times_done.to_i ] }

      @services_revenue = services_raw.sort_by { |r| -r.total_revenue.to_i }
                                      .first(10)
                                      .to_h { |r| [ r.service_name, r.total_revenue.to_i ] }

      # Tabla resumen mensual: últimos 12 meses
      monthly_raw = AttendanceItem
        .joins(:attendance)
        .where("attendances.attended_on >= ?", 12.months.ago.beginning_of_month)
        .group(Arel.sql("DATE_TRUNC('month', attendances.attended_on)"))
        .select(
          Arel.sql("DATE_TRUNC('month', attendances.attended_on) AS month"),
          "SUM(attendance_items.price_cents)                                            AS total_cents",
          "SUM(ROUND(attendance_items.price_cents / 1.19))                              AS net_cents",
          "SUM(attendance_items.price_cents - ROUND(attendance_items.price_cents / 1.19)) AS iva_cents",
          "SUM(attendance_items.commission_cents)                                        AS stylist_cents"
        )
        .order(Arel.sql("DATE_TRUNC('month', attendances.attended_on)"))

      @monthly_summary = monthly_raw.map do |r|
        net     = r.net_cents.to_i
        stylist = r.stylist_cents.to_i
        {
          month:        Date.parse(r.month.to_s).strftime("%b %Y").capitalize,
          total:        r.total_cents.to_i,
          iva:          r.iva_cents.to_i,
          net:          net,
          stylist:      stylist,
          studio:       net - stylist
        }
      end

      # Stock crítico
      @critical_stock = Product.active.where("stock_quantity <= 3").order(:stock_quantity)
    end
  end
end
