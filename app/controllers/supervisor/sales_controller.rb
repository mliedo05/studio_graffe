module Supervisor
  class SalesController < BaseController
    def index
      range = period_range

      # Ventas de productos en atenciones
      @product_sales = AttendanceItem
        .joins(:attendance, :product)
        .includes(:product, attendance: :attendance_payments)
        .where(item_type: "product", attendances: { attended_on: range })
        .order("attendances.attended_on DESC")

      @product_totals = AttendanceItem
        .joins(:attendance, :product)
        .where(item_type: "product", attendances: { attended_on: range })
        .group("products.name", "products.brand")
        .select(
          "products.name AS product_name",
          "products.brand AS product_brand",
          "COUNT(*) AS units_sold",
          "SUM(attendance_items.price_cents) AS total_cents"
        )

      # Ventas de tienda online (órdenes pagadas)
      @online_orders = Order.where(status: "paid", created_at: range.first.beginning_of_day..range.last.end_of_day)
      @online_total  = @online_orders.sum(:total_cents)
    end
  end
end
