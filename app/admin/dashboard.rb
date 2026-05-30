# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "📊 Dashboard"

  content title: "Panel de administración" do
    # ── Tarjetas de resumen ──────────────────────────────────────────
    columns do
      column do
        panel "🛒 Órdenes hoy" do
          count = Order.where(created_at: Time.current.beginning_of_day..).count
          h2 count, style: "font-size:2.5rem; font-weight:bold; color:#d97706; margin:0"
          para "órdenes creadas hoy"
        end
      end
      column do
        panel "📈 Margen bruto del mes" do
          items = OrderItem.joins(:order)
                           .where(orders: { status: "paid", created_at: Time.current.beginning_of_month.. })
                           .where.not(total_cost_cents: nil)
          ventas = items.sum(:total_price_cents)
          costos = items.sum(:total_cost_cents)
          margen = ventas - costos
          pct    = ventas > 0 ? (margen.to_f / ventas * 100).round(1) : 0
          color  = margen > 0 ? "#16a34a" : "#dc2626"
          h2 number_to_currency(margen, unit: "$", delimiter: ".", precision: 0),
             style: "font-size:1.8rem; font-weight:bold; color:#{color}; margin:0"
          para "#{pct}% margen bruto este mes"
        end
      end
      column do
        panel "💰 Ventas del mes" do
          total = Order.where(status: "paid")
                       .where(created_at: Time.current.beginning_of_month..)
                       .sum(:total_cents)
          h2 number_to_currency(total, unit: "$", delimiter: ".", precision: 0),
             style: "font-size:2rem; font-weight:bold; color:#16a34a; margin:0"
          para "en órdenes pagadas este mes"
        end
      end
      column do
        panel "📦 Stock crítico" do
          count = Product.active.where("stock_quantity <= 3").count
          color = count > 0 ? "#dc2626" : "#16a34a"
          h2 count, style: "font-size:2.5rem; font-weight:bold; color:#{color}; margin:0"
          para "productos con 3 unidades o menos"
        end
      end
      column do
        panel "👥 Clientes" do
          count = User.where(role: "client").count
          h2 count, style: "font-size:2.5rem; font-weight:bold; color:#6366f1; margin:0"
          para "clientes registrados"
        end
      end
    end

    # ── Órdenes recientes ────────────────────────────────────────────
    columns do
      column do
        panel "📋 Últimas 10 órdenes" do
          table_for Order.order(created_at: :desc).limit(10) do
            column("Número")    { |o| link_to o.number, admin_order_path(o) }
            column("Cliente")   { |o| o.user.full_name }
            column("Estado") do |o|
              color = case o.status
              when "paid"      then "#16a34a"
              when "checkout"  then "#d97706"
              when "cancelled" then "#dc2626"
              else "#6b7280"
              end
              span o.status, style: "background:#{color}; color:white; padding:2px 8px; border-radius:4px; font-size:11px; font-weight:bold"
            end
            column("Total")     { |o| number_to_currency(o.total_cents, unit: "$", delimiter: ".", precision: 0) }
            column("Fecha")     { |o| o.created_at.strftime("%d/%m %H:%M") }
          end
        end
      end

      column do
        panel "⚠️ Productos con stock crítico (≤ 3 unidades)" do
          products = Product.active.where("stock_quantity <= 3").order(:stock_quantity)
          if products.any?
            table_for products do
              column("Producto") { |p| link_to p.name, edit_admin_product_path(p) }
              column("Marca")    { |p| p.brand }
              column("Stock") do |p|
                color = p.stock_quantity == 0 ? "#dc2626" : "#d97706"
                span p.stock_quantity, style: "font-weight:bold; color:#{color}"
              end
            end
          else
            para "✅ Todos los productos tienen stock suficiente.", style: "color:#16a34a"
          end
        end
      end
    end

    # ── Acceso rápido al panel Supervisor ────────────────────────────
    panel "🗂️ Panel Supervisor — Acceso directo" do
      div style: "margin-bottom:12px; font-size:13px; color:#6b7280;" do
        text_node "Gestión de atenciones, comisiones, caja y ventas del salón."
      end

      btn_style = "display:inline-block; padding:10px 20px; margin:4px; border-radius:8px; font-size:13px; font-weight:600; text-decoration:none; border:none; cursor:pointer;"

      links = [
        { label: "📊 Dashboard supervisor", path: :supervisor_root_path,        bg: "#1A1A1A", color: "#C9A96E" },
        { label: "📋 Registro de atenciones", path: :supervisor_attendances_path, bg: "#fff",   color: "#1A1A1A", border: "1px solid #e5e7eb" },
        { label: "➕ Nueva atención",          path: :new_supervisor_attendance_path, bg: "#C9A96E", color: "#fff" },
        { label: "💵 Caja",                   path: :supervisor_caja_path,        bg: "#fff",   color: "#16a34a", border: "1px solid #bbf7d0" },
        { label: "💰 Comisiones",             path: :supervisor_commissions_path, bg: "#fff",   color: "#7c3aed", border: "1px solid #ddd6fe" },
        { label: "🛍️ Ventas",                path: :supervisor_sales_path,       bg: "#fff",   color: "#2563eb", border: "1px solid #bfdbfe" }
      ]

      links.each do |lnk|
        style = btn_style + "background:#{lnk[:bg]}; color:#{lnk[:color]};"
        style += "border:#{lnk[:border]};" if lnk[:border]
        link_to lnk[:label], send(lnk[:path]), style: style, target: "_blank"
      end
    end
  end
end
