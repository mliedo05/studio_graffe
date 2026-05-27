ActiveAdmin.register InventoryEntry do
  menu label: "📥 Inventario", priority: 3

  permit_params :product_id, :quantity_received, :unit_cost_cents,
                :supplier, :invoice_number, :received_at, :notes

  # ── Listado ──────────────────────────────────────────────────────
  index do
    selectable_column
    column("Fecha recepción") { |e| e.received_at.strftime("%d/%m/%Y %H:%M") }
    column("Producto") do |e|
      div link_to(e.product.name, admin_inventory_entry_path(e)), style: "font-weight:600"
      div e.product.brand, style: "color:#6b7280; font-size:12px"
    end
    column("N° Factura") { |e| span e.invoice_number, style: "font-family:monospace" }
    column("Proveedor")  { |e| e.supplier }
    column("Recibido")   { |e| "#{e.quantity_received} uds." }
    column("Disponible") do |e|
      color = e.fully_consumed? ? "#9ca3af" : "#16a34a"
      span "#{e.quantity_remaining} uds.",
           style: "font-weight:bold; color:#{color}"
    end
    column("Costo unit.") { |e| number_to_currency(e.unit_cost_cents, unit: "$", delimiter: ".", precision: 0) }
    column("Costo total") { |e| number_to_currency(e.quantity_received * e.unit_cost_cents, unit: "$", delimiter: ".", precision: 0) }
    column("Estado") do |e|
      if e.fully_consumed?
        span "Agotado", style: "background:#f3f4f6; color:#6b7280; padding:2px 8px; border-radius:4px; font-size:11px"
      else
        span "Disponible", style: "background:#dcfce7; color:#16a34a; padding:2px 8px; border-radius:4px; font-size:11px; font-weight:bold"
      end
    end
    actions
  end

  # ── Filtros ───────────────────────────────────────────────────────
  filter :product,          label: "Producto"
  filter :supplier_cont,    label: "Proveedor contiene"
  filter :invoice_number_cont, label: "N° Factura contiene"
  filter :received_at_gteq, label: "Recibido desde"
  filter :received_at_lteq, label: "Recibido hasta"

  # ── Formulario ────────────────────────────────────────────────────
  form do |f|
    f.inputs "📥 Registrar entrada de inventario" do
      f.input :product,
              label:        "Producto",
              hint:         "Selecciona el producto que estás ingresando al stock",
              include_blank: "— Selecciona un producto —"

      f.input :received_at,
              label:        "Fecha y hora de recepción",
              as:           :datetime_picker,
              input_html:   { value: f.object.received_at || Time.current }

      f.input :invoice_number,
              label: "Número de factura",
              hint:  "Ej: F-001-2024 o 12345"

      f.input :supplier,
              label: "Proveedor",
              hint:  "Nombre del proveedor o distribuidor"

      f.input :quantity_received,
              label: "Cantidad recibida (unidades)",
              hint:  "Número de unidades que llegaron físicamente"

      f.input :unit_cost_cents,
              label: "Costo unitario (en pesos)",
              hint:  "Precio que pagaste por cada unidad, sin puntos. Ej: 3500"

      f.input :notes,
              label: "Notas",
              as:    :text,
              input_html: { rows: 3 },
              hint:  "Observaciones opcionales (estado del producto, condiciones, etc.)"
    end

    # Vista previa del costo total calculado
    if f.object.quantity_received.to_i > 0 && f.object.unit_cost_cents.to_i > 0
      f.inputs "💰 Resumen" do
        total = f.object.quantity_received * f.object.unit_cost_cents
        li "Costo total de esta entrada: #{number_to_currency(total, unit: '$', delimiter: '.', precision: 0)}"
      end
    end

    f.actions do
      f.action :submit, label: "✅ Registrar entrada"
      f.action :cancel
    end
  end

  # ── Vista detalle ─────────────────────────────────────────────────
  show do
    columns do
      column do
        attributes_table title: "📋 Detalle de la entrada" do
          row("Producto")          { |e| link_to e.product.name, admin_product_path(e.product) }
          row("Marca")             { |e| e.product.brand }
          row("Fecha recepción")   { |e| e.received_at.strftime("%d/%m/%Y %H:%M") }
          row("N° Factura")        { |e| span e.invoice_number, style: "font-family:monospace; font-weight:bold" }
          row("Proveedor")         { |e| e.supplier }
          row("Unidades recibidas") { |e| e.quantity_received }
          row("Unidades restantes") do |e|
            color = e.fully_consumed? ? "#9ca3af" : "#16a34a"
            span e.quantity_remaining, style: "font-weight:bold; color:#{color}"
          end
          row("Costo unitario") { |e| number_to_currency(e.unit_cost_cents, unit: "$", delimiter: ".", precision: 0) }
          row("Costo total del lote") do |e|
            number_to_currency(e.quantity_received * e.unit_cost_cents, unit: "$", delimiter: ".", precision: 0)
          end
          row("Estado") do |e|
            e.fully_consumed? ? "✅ Lote completamente vendido" : "📦 #{e.quantity_remaining} unidades disponibles"
          end
          row("Notas") { |e| e.notes.presence || "—" }
          row("Registrado el") { |e| e.created_at.strftime("%d/%m/%Y %H:%M") }
        end
      end

      column do
        panel "📊 Stock actual del producto" do
          product = inventory_entry.product
          attributes_table_for product do
            row("Producto")        { product.name }
            row("Stock total")     { "#{product.stock_quantity} unidades" }
            row("Costo prom. FIFO") do
              wac = product.weighted_average_cost
              number_to_currency(wac.fractional, unit: "$", delimiter: ".", precision: 0)
            end
            row("Precio de venta") { number_to_currency(product.price_cents, unit: "$", delimiter: ".", precision: 0) }
            row("Margen estimado") do
              wac = product.weighted_average_cost.fractional
              if wac > 0
                margin = product.price_cents - wac
                pct    = (margin.to_f / product.price_cents * 100).round(1)
                color  = pct > 0 ? "#16a34a" : "#dc2626"
                span "#{number_to_currency(margin, unit: '$', delimiter: '.', precision: 0)} (#{pct}%)",
                     style: "font-weight:bold; color:#{color}"
              else
                span "Sin datos de costo", style: "color:#9ca3af"
              end
            end
          end
        end

        panel "📦 Todos los lotes de este producto" do
          table_for inventory_entry.product.inventory_entries.order(received_at: :desc) do
            column("Fecha")    { |e| e.received_at.strftime("%d/%m/%Y") }
            column("Factura")  { |e| e.invoice_number }
            column("Recibido") { |e| e.quantity_received }
            column("Restante") { |e| e.quantity_remaining }
            column("Costo")    { |e| number_to_currency(e.unit_cost_cents, unit: "$", delimiter: ".", precision: 0) }
          end
        end
      end
    end
  end

  # Al crear, actualiza el stock del producto automáticamente
  controller do
    def create
      @inventory_entry = InventoryEntry.new(permitted_params[:inventory_entry])
      if @inventory_entry.valid?
        product = @inventory_entry.product
        product.receive_stock!(
          quantity:        @inventory_entry.quantity_received,
          unit_cost_cents: @inventory_entry.unit_cost_cents,
          supplier:        @inventory_entry.supplier,
          invoice_number:  @inventory_entry.invoice_number,
          received_at:     @inventory_entry.received_at,
          notes:           @inventory_entry.notes
        )
        redirect_to admin_inventory_entries_path,
                    notice: "✅ Entrada registrada. Stock de #{product.name} actualizado a #{product.reload.stock_quantity} unidades."
      else
        render :new, status: :unprocessable_entity
      end
    end
  end
end
