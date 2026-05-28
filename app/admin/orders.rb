ActiveAdmin.register Order do
  menu label: "📦 Órdenes", priority: 3

  actions :index, :show

  # ── Ransack: permitir búsqueda por atributos del usuario ─────────
  config.sort_order = "created_at_desc"
  config.per_page   = 50

  # ── Filtros sidebar (complementan el buscador inline) ────────────
  filter :payment_method, as: :select,
         collection: [ [ "Getnet", "getnet" ], [ "Efectivo", "efectivo" ] ],
         label: "Método de pago"
  filter :shipping_type, as: :select,
         collection: [ [ "Retiro", "pickup" ], [ "Delivery", "delivery" ] ],
         label: "Tipo de envío"

  # ── Panel resumen encima del listado ─────────────────────────────
  index do
    # ── Barra de búsqueda + fechas inline ──────────────────────────
    div style: "background:#fff; border:1px solid #e5e7eb; border-radius:8px; padding:16px 20px; margin-bottom:20px;" do
      div style: "font-size:12px; font-weight:700; color:#6b7280; text-transform:uppercase; letter-spacing:0.08em; margin-bottom:12px;" do
        "🔍 Buscar órdenes"
      end
      render partial: "admin/orders/search_form", locals: { url: admin_orders_path }
    end

    scope_orders = collection

    paid_orders      = scope_orders.where(status: "paid")
    cancelled_orders = scope_orders.where(status: "cancelled")
    checkout_orders  = scope_orders.where(status: "checkout")
    cart_orders      = scope_orders.where(status: "cart")

    paid_total      = paid_orders.sum(:total_cents)
    cancelled_total = cancelled_orders.sum(:total_cents)

    # ── Tarjetas de resumen ──
    div style: "display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:24px;" do
      # Ventas pagadas
      div style: "background:#f0fdf4; border:1px solid #bbf7d0; border-radius:8px; padding:20px;" do
        div style: "font-size:11px; font-weight:700; letter-spacing:0.08em; text-transform:uppercase; color:#16a34a; margin-bottom:8px;" do
          "✅ Ventas pagadas"
        end
        div style: "font-size:28px; font-weight:800; color:#15803d; line-height:1;" do
          number_to_currency(paid_total, unit: "$", delimiter: ".", precision: 0)
        end
        div style: "font-size:13px; color:#4ade80; margin-top:6px;" do
          "#{paid_orders.count} #{"orden".pluralize(paid_orders.count)}"
        end
      end

      # Canceladas
      div style: "background:#fef2f2; border:1px solid #fecaca; border-radius:8px; padding:20px;" do
        div style: "font-size:11px; font-weight:700; letter-spacing:0.08em; text-transform:uppercase; color:#dc2626; margin-bottom:8px;" do
          "❌ Canceladas"
        end
        div style: "font-size:28px; font-weight:800; color:#b91c1c; line-height:1;" do
          number_to_currency(cancelled_total, unit: "$", delimiter: ".", precision: 0)
        end
        div style: "font-size:13px; color:#f87171; margin-top:6px;" do
          "#{cancelled_orders.count} #{"orden".pluralize(cancelled_orders.count)}"
        end
      end

      # En proceso (checkout)
      div style: "background:#fffbeb; border:1px solid #fde68a; border-radius:8px; padding:20px;" do
        div style: "font-size:11px; font-weight:700; letter-spacing:0.08em; text-transform:uppercase; color:#d97706; margin-bottom:8px;" do
          "⏳ En proceso"
        end
        div style: "font-size:28px; font-weight:800; color:#b45309; line-height:1;" do
          checkout_orders.count.to_s
        end
        div style: "font-size:13px; color:#fbbf24; margin-top:6px;" do
          "#{checkout_orders.count == 1 ? "orden esperando pago" : "órdenes esperando pago"}"
        end
      end

      # Carritos activos
      div style: "background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:20px;" do
        div style: "font-size:11px; font-weight:700; letter-spacing:0.08em; text-transform:uppercase; color:#6b7280; margin-bottom:8px;" do
          "🛒 Carritos activos"
        end
        div style: "font-size:28px; font-weight:800; color:#374151; line-height:1;" do
          cart_orders.count.to_s
        end
        div style: "font-size:13px; color:#9ca3af; margin-top:6px;" do
          "sin confirmar"
        end
      end
    end

    # ── Tabla de órdenes ──
    selectable_column
    column("Orden") { |o| link_to o.number, admin_order_path(o), style: "font-weight:600; font-family:monospace" }
    column("Cliente") do |o|
      div o.user.full_name, style: "font-weight:500"
      div o.user.email, style: "color:#6b7280; font-size:11px"
    end
    column("Estado") do |o|
      styles = {
        "paid"      => "background:#dcfce7; color:#16a34a",
        "checkout"  => "background:#fef3c7; color:#d97706",
        "cancelled" => "background:#fee2e2; color:#dc2626",
        "cart"      => "background:#f3f4f6; color:#6b7280",
        "shipped"   => "background:#dbeafe; color:#1d4ed8",
        "delivered" => "background:#ede9fe; color:#7c3aed"
      }
      label = {
        "paid"      => "✅ Pagado",
        "checkout"  => "⏳ En proceso",
        "cancelled" => "❌ Cancelado",
        "cart"      => "🛒 Carrito",
        "shipped"   => "🚚 Enviado",
        "delivered" => "🏠 Entregado"
      }
      span(label[o.status] || o.status,
           style: "#{styles[o.status]}; padding:3px 8px; border-radius:4px; font-size:11px; font-weight:bold")
    end
    column("Pago") do |o|
      o.payment_method.presence || span("—", style: "color:#9ca3af")
    end
    column("Envío") do |o|
      o.shipping_type == "delivery" ? "🚚 Delivery" : "🏪 Retiro"
    end
    column("Total") { |o| number_to_currency(o.total_cents, unit: "$", delimiter: ".", precision: 0) }
    column("Fecha") { |o| o.created_at.strftime("%d/%m/%Y %H:%M") }
    actions only: [ :show ]
  end

  # ── Vista detalle ─────────────────────────────────────────────────
  show do
    columns do
      column do
        attributes_table title: "📋 Resumen de la orden" do
          row("Número")          { |o| span o.number, style: "font-family:monospace; font-weight:bold" }
          row("Estado") do |o|
            label = { "paid" => "✅ Pagado", "checkout" => "⏳ En proceso",
                      "cancelled" => "❌ Cancelado", "cart" => "🛒 Carrito",
                      "shipped" => "🚚 Enviado", "delivered" => "🏠 Entregado" }
            label[o.status] || o.status
          end
          row("Método de pago")  { |o| o.payment_method.presence || "—" }
          row("ID transacción")  { |o| o.transaction_id.presence || "—" }
          row("Total")           { |o| number_to_currency(o.total_cents, unit: "$", delimiter: ".", precision: 0) }
          row("Fecha")           { |o| o.created_at.strftime("%d/%m/%Y %H:%M") }
        end

        attributes_table title: "🧾 Facturación" do
          row("Nombre")      { |o| "#{o.billing_first_name} #{o.billing_last_name}" }
          row("Documento")   { |o| "#{o.billing_document_type&.upcase}: #{o.billing_document_number}" }
          row("Email")       { |o| o.billing_email }
          row("Teléfono")    { |o| o.billing_phone }
        end
      end

      column do
        attributes_table title: "🚚 Envío" do
          row("Tipo") { |o| o.shipping_type == "delivery" ? "🚚 Delivery" : "🏪 Retiro en tienda" }
          if order.shipping_type == "delivery"
            row("Destinatario")    { |o| o.shipping_recipient_name }
            row("Teléfono envío")  { |o| o.shipping_phone }
            row("Región")          { |o| o.shipping_region }
            row("Comuna")          { |o| o.shipping_comuna }
            row("Ciudad")          { |o| o.shipping_city }
            row("Dirección") do |o|
              "#{o.shipping_street} #{o.shipping_street_number}#{o.shipping_apartment.present? ? ", #{o.shipping_apartment}" : ""}"
            end
          end
        end

        panel "🛍️ Productos" do
          table_for order.order_items.includes(:product) do
            column("Producto")        { |i| i.product.name }
            column("Marca")           { |i| i.product.brand }
            column("Cantidad")        { |i| i.quantity }
            column("Precio unitario") { |i| number_to_currency(i.unit_price_cents, unit: "$", delimiter: ".", precision: 0) }
            column("Subtotal")        { |i| number_to_currency(i.total_price_cents, unit: "$", delimiter: ".", precision: 0) }
          end
          div style: "text-align:right; font-weight:bold; padding:8px 0; border-top:2px solid #e5e7eb; margin-top:8px" do
            "TOTAL: #{number_to_currency(order.total_cents, unit: "$", delimiter: ".", precision: 0)}"
          end
        end
      end
    end
  end
end
