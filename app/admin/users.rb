ActiveAdmin.register User do
  menu label: "👥 Usuarios", priority: 4

  permit_params :first_name, :last_name, :email, :phone, :role,
                :password, :password_confirmation

  # ── Listado ──────────────────────────────────────────────────────
  index do
    selectable_column
    id_column
    column("Nombre") do |u|
      div link_to(u.full_name, edit_admin_user_path(u)), style: "font-weight:600"
      div u.email, style: "color:#6b7280; font-size:12px"
    end
    column("Rol") do |u|
      colors = { "admin" => "#7c3aed", "stylist" => "#0369a1", "client" => "#374151" }
      span u.role,
           style: "background:#{colors[u.role] || "#6b7280"}; color:white; padding:2px 8px; border-radius:4px; font-size:11px; font-weight:bold; text-transform:uppercase"
    end
    column("Teléfono") { |u| u.phone.presence || span("—", style: "color:#9ca3af") }
    column("Registrado") { |u| u.created_at.strftime("%d/%m/%Y") }
    column("Órdenes") do |u|
      count = u.orders.where(status: "paid").count
      link_to "#{count} pagadas", admin_orders_path(q: { user_id_eq: u.id })
    end
    actions
  end

  # ── Filtros ───────────────────────────────────────────────────────
  filter :role, as: :select, collection: User::ROLES, label: "Rol"
  filter :email_cont,       label: "Email contiene"
  filter :first_name_cont,  label: "Nombre contiene"

  # ── Formulario ────────────────────────────────────────────────────
  form do |f|
    f.inputs "👤 Datos personales" do
      f.input :first_name, label: "Nombre"
      f.input :last_name,  label: "Apellido"
      f.input :email,      label: "Email"
      f.input :phone,      label: "Teléfono"
      f.input :role, as: :select,
              collection: User::ROLES.map { |r| [ r.capitalize, r ] },
              label: "Rol"
    end

    f.inputs "🔑 Cambiar contraseña" do
      span "Deja en blanco para mantener la contraseña actual.",
           style: "color:#6b7280; font-size:12px; display:block; margin-bottom:8px; padding:0 16px"
      f.input :password,              label: "Nueva contraseña",   hint: "Mínimo 6 caracteres", required: false, input_html: { autocomplete: "new-password" }
      f.input :password_confirmation, label: "Confirmar contraseña", required: false, input_html: { autocomplete: "new-password" }
    end

    f.actions
  end

  # ── Vista detalle ─────────────────────────────────────────────────
  show do
    columns do
      column do
        attributes_table title: "Datos personales" do
          row("Nombre")      { |u| u.full_name }
          row("Email")       { |u| u.email }
          row("Teléfono")    { |u| u.phone.presence || "—" }
          row("Rol")         { |u| u.role }
          row("Registrado")  { |u| u.created_at.strftime("%d/%m/%Y %H:%M") }
        end
      end
      column do
        panel "🛒 Historial de compras" do
          orders = user.orders.where.not(status: "cart").order(created_at: :desc).limit(10)
          if orders.any?
            table_for orders do
              column("Orden")   { |o| link_to o.number, admin_order_path(o) }
              column("Estado")  { |o| o.status }
              column("Total")   { |o| number_to_currency(o.total_cents, unit: "$", delimiter: ".", precision: 0) }
              column("Fecha")   { |o| o.created_at.strftime("%d/%m/%Y") }
            end
          else
            para "Sin compras registradas.", style: "color:#9ca3af"
          end
        end
      end
    end
  end

  # Manejo seguro del password: solo actualiza si se envió algo
  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      super
    end
  end
end
