module Supervisor
  class CommissionsController < BaseController
    def index
      range = period_range

      @stylists = User.stylists.includes(:stylist_profile)

      # Comisiones agrupadas por estilista
      raw = AttendanceItem
        .joins(:attendance, :stylist)
        .where(attendances: { attended_on: range })
        .group("users.id", "users.first_name", "users.last_name")
        .select(
          "users.id          AS stylist_id",
          "users.first_name  AS stylist_first_name",
          "users.last_name   AS stylist_last_name",
          "SUM(attendance_items.price_cents)      AS total_sales_cents",
          "SUM(attendance_items.commission_cents) AS total_commission_cents",
          "COUNT(*)                               AS items_count"
        )

      @commission_summary = raw.map do |r|
        {
          stylist_id:             r.stylist_id,
          name:                   "#{r.stylist_first_name} #{r.stylist_last_name}",
          total_sales_cents:      r.total_sales_cents.to_i,
          total_commission_cents: r.total_commission_cents.to_i,
          items_count:            r.items_count.to_i
        }
      end

      # Detalle por estilista seleccionada
      if params[:stylist_id].present?
        @selected_stylist = User.find(params[:stylist_id])
        @items = AttendanceItem
          .joins(:attendance)
          .includes(:attendance, :service, :product)
          .where(stylist_id: @selected_stylist.id, attendances: { attended_on: range })
          .order("attendances.attended_on DESC")
        @pagy, @items = pagy(@items, items: 50)
      end

      # Datos para gráfico de barras
      @chart_data = @commission_summary.map { |s| [ s[:name], s[:total_commission_cents] ] }.to_h

      # Una sola consulta agrupa frecuencia + ingresos por servicio
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
    end
  end
end
