ActiveAdmin.register User, as: "Client" do
  menu label: "👤 Clientes", priority: 5

  # Solo usuarios con rol "client"
  scope_to(if: proc { true }) { User.clients }

  permit_params :first_name, :last_name, :email, :phone

  # ── Listado ──────────────────────────────────────────────────────
  index title: "Clientes" do
    selectable_column
    column("Nombre") { |u| link_to u.full_name, admin_client_path(u) }
    column :email
    column("Teléfono") { |u| u.phone.presence || "—" }
    column("Atenciones") do |u|
      count = u.attendances_as_client.count
      span count.to_s,
           style: "background:#dbeafe; color:#1d4ed8; padding:2px 10px; border-radius:12px; font-size:12px; font-weight:600;"
    end
    column("Compras") do |u|
      count = u.orders.where(status: %w[paid shipped delivered]).count
      span count.to_s,
           style: "background:#dcfce7; color:#16a34a; padding:2px 10px; border-radius:12px; font-size:12px; font-weight:600;"
    end
    column("Última visita") do |u|
      last = u.attendances_as_client.ordered.first
      last ? last.attended_on.strftime("%d/%m/%Y") : content_tag(:span, "Sin atenciones", style: "color:#d1d5db;")
    end
    column("Registrada") { |u| u.created_at.strftime("%d/%m/%Y") }
    actions
  end

  # ── Filtros ───────────────────────────────────────────────────────
  filter :first_name_cont, label: "Nombre"
  filter :last_name_cont,  label: "Apellido"
  filter :email_cont,      label: "Email"
  filter :phone_cont,      label: "Teléfono"
  filter :created_at,      label: "Fecha de registro"

  # ── Formulario (edición básica) ───────────────────────────────────
  form title: "Editar cliente" do |f|
    f.inputs "Datos personales" do
      f.input :first_name, label: "Nombre"
      f.input :last_name,  label: "Apellido"
      f.input :email,      label: "Email"
      f.input :phone,      label: "Teléfono"
    end
    f.actions
  end

  # ── Vista detalle ─────────────────────────────────────────────────
  show title: proc { |u| u.full_name } do
    attendances = resource.attendances_as_client
                          .includes(:attendance_items, :attendance_payments)
                          .ordered
    orders = resource.orders
                     .where(status: %w[paid shipped delivered])
                     .order(created_at: :desc)

    total_attendances = resource.attendances_as_client.sum(:total_cents)
    total_orders      = orders.sum(:total_cents)

    # ── KPIs ──────────────────────────────────────────────────────
    div style: "display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:24px;" do
      [
        ["Atenciones",          attendances.count.to_s,          "#1d4ed8", "#dbeafe"],
        ["Total en atenciones", number_to_currency(total_attendances, unit: "$", delimiter: ".", precision: 0), "#92400e", "#fef3c7"],
        ["Compras online",      orders.count.to_s,               "#16a34a", "#dcfce7"],
        ["Total en compras",    number_to_currency(total_orders, unit: "$", delimiter: ".", precision: 0), "#16a34a", "#dcfce7"]
      ].each do |label, value, color, bg|
        div style: "background:#{bg}; border-radius:12px; padding:16px 20px;" do
          div style: "font-size:11px; color:#{color}; font-weight:600; text-transform:uppercase; letter-spacing:0.06em; margin-bottom:4px;" do
            label
          end
          div style: "font-size:22px; font-weight:700; color:#{color};" do
            value
          end
        end
      end
    end

    columns do
      column do
        # ── Datos personales ────────────────────────────────────────
        attributes_table title: "Información" do
          row("Nombre")      { resource.full_name }
          row("Email")       { resource.email }
          row("Teléfono")    { resource.phone.presence || "—" }
          row("Registrada")  { resource.created_at.strftime("%d/%m/%Y") }
        end

        # ── Atenciones ──────────────────────────────────────────────
        panel "✂️ Historial de atenciones (#{attendances.count})" do
          if attendances.any?
            table_for attendances do
              column("N°") do |a|
                link_to a.number,
                        supervisor_attendance_path(a),
                        target: "_blank",
                        style: "font-family:monospace; font-size:12px; color:#1d4ed8;"
              end
              column("Fecha")  { |a| a.attended_on.strftime("%d/%m/%Y") }
              column("Items")  { |a| "#{a.attendance_items.size} item(s)" }
              column("Total")  { |a| number_to_currency(a.total_cents, unit: "$", delimiter: ".", precision: 0) }
              column("Pagado") { |a| number_to_currency(a.paid_cents,  unit: "$", delimiter: ".", precision: 0) }
              column("Estado") do |a|
                if a.status == "closed"
                  status_tag("Cerrada", class: "yes")
                else
                  status_tag("Abierta")
                end
              end
            end
          else
            div "Sin atenciones registradas.", style: "color:#9ca3af; padding:16px 0;"
          end
        end
      end

      column do
        # ── Compras online ──────────────────────────────────────────
        panel "🛍️ Compras online (#{orders.count})" do
          if orders.any?
            table_for orders do
              column("Orden")  { |o| content_tag(:code, o.number, style: "font-size:12px;") }
              column("Fecha")  { |o| o.created_at.strftime("%d/%m/%Y") }
              column("Productos") do |o|
                "#{o.item_count} producto(s)"
              end
              column("Total")  { |o| number_to_currency(o.total_cents, unit: "$", delimiter: ".", precision: 0) }
              column("Estado") do |o|
                labels = { "paid" => "Pagada", "shipped" => "Enviada", "delivered" => "Entregada" }
                status_tag(labels[o.status] || o.status, class: "yes")
              end
            end
          else
            div "Sin compras online registradas.", style: "color:#9ca3af; padding:16px 0;"
          end
        end
      end
    end
  end

  # No permitir eliminar clientes con atenciones
  before_destroy do |user|
    if user.attendances_as_client.exists?
      flash[:error] = "No se puede eliminar una clienta con atenciones registradas."
      redirect_to admin_clients_path
    end
  end

  controller do
    def update
      # No cambiar el rol desde este formulario
      params[:user]&.delete(:role)
      super
    end
  end
end
