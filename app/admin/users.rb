ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :phone, :role, :password, :password_confirmation,
                :avatar,
                stylist_profile_attributes: [ :id, :commission_percentage ]

  index do
    selectable_column
    id_column
    column("Foto") do |u|
      if u.avatar.attached?
        image_tag url_for(u.avatar),
                  style: "width:40px; height:40px; border-radius:50%; object-fit:cover; border:1px solid #e5e7eb;"
      elsif u.avatar_url.present?
        image_tag u.avatar_url,
                  style: "width:40px; height:40px; border-radius:50%; object-fit:cover; border:1px solid #e5e7eb;"
      else
        content_tag(:div, u.first_name[0],
                    style: "width:40px; height:40px; border-radius:50%; background:linear-gradient(135deg,#C9A96E,#8B7355); color:#fff; display:flex; align-items:center; justify-content:center; font-weight:600; font-size:16px;")
      end
    end
    column("Nombre") { |u| u.full_name }
    column :email
    column("Comisión %") do |u|
      if u.stylist?
        pct = u.stylist_profile&.commission_percentage
        span "#{pct}%", style: "font-weight:bold; color:#7c3aed; background:#ede9fe; padding:2px 8px; border-radius:4px; font-size:12px;"
      else
        span "—", style: "color:#9ca3af;"
      end
    end
    column("Rol") { |u|
      labels = {
        "admin"      => [ "⚙️ Admin",      "background:#ede9fe; color:#7c3aed" ],
        "supervisor" => [ "👁️ Supervisor", "background:#fef3c7; color:#d97706" ],
        "stylist"    => [ "✂️ Estilista",  "background:#dbeafe; color:#1d4ed8" ],
        "client"     => [ "👤 Cliente",    "background:#f3f4f6; color:#6b7280" ]
      }
      text, style = labels[u.role] || [ u.role, "background:#f3f4f6; color:#6b7280" ]
      span text, style: "#{style}; padding:3px 8px; border-radius:4px; font-size:11px; font-weight:bold"
    }
    column :phone
    column :created_at
    actions
  end

  filter :role, as: :select,
         collection: User::ROLES.map { |r| [ r.capitalize, r ] },
         label: "Rol"
  filter :email_cont,      label: "Email"
  filter :first_name_cont, label: "Nombre"

  form do |f|
    f.inputs "Datos del usuario" do
      f.input :first_name, label: "Nombre"
      f.input :last_name,  label: "Apellido"
      f.input :email,      label: "Email"
      f.input :phone,      label: "Teléfono"
      f.input :role, as: :select,
              label: "Rol",
              collection: User::ROLES.map { |r| [ r.capitalize, r ] }
    end
    f.inputs "📷 Foto de perfil" do
      if f.object.persisted? && f.object.avatar.attached?
        div do
          image_tag url_for(f.object.avatar),
                    style: "width:100px; height:100px; border-radius:50%; object-fit:cover; border:2px solid #e5e7eb; margin-bottom:10px; display:block;"
        end
        div style: "font-size:12px; color:#6b7280; margin-bottom:8px;" do
          "Foto actual. Sube una nueva para reemplazarla."
        end
      elsif f.object.avatar_url.present?
        div do
          image_tag f.object.avatar_url,
                    style: "width:100px; height:100px; border-radius:50%; object-fit:cover; border:2px solid #e5e7eb; margin-bottom:10px; display:block;"
        end
        div style: "font-size:12px; color:#6b7280; margin-bottom:8px;" do
          "Foto desde Google. Sube una foto propia para reemplazarla."
        end
      end
      f.input :avatar, as: :file, label: "Subir foto (JPG, PNG — se recomienda cuadrada)"
    end

    if f.object.stylist? || f.object.new_record?
      f.inputs "✂️ Perfil de estilista" do
        f.fields_for :stylist_profile, (f.object.stylist_profile || f.object.build_stylist_profile) do |sp|
          sp.input :commission_percentage,
                   label: "Comisión (%)",
                   hint: "Porcentaje que se pre-carga al asignar esta estilista en una atención. Rango: 0–100."
        end
      end
    end

    f.inputs "Contraseña #{f.object.new_record? ? "(requerida)" : "(dejar en blanco para no cambiar)"}" do
      f.input :password,              label: "Contraseña",         required: f.object.new_record?
      f.input :password_confirmation, label: "Confirmar contraseña", required: f.object.new_record?
    end
    f.actions
  end

  # ── Vista detalle ─────────────────────────────────────────────────
  show do
    columns do
      column do
        attributes_table title: "Información" do
          row("Nombre")    { |u| u.full_name }
          row("Email")     { |u| u.email }
          row("Teléfono")  { |u| u.phone.presence || "—" }
          row("Rol") do |u|
            labels = {
              "admin"      => [ "⚙️ Admin",      "#7c3aed" ],
              "supervisor" => [ "👁️ Supervisor", "#d97706" ],
              "stylist"    => [ "✂️ Estilista",  "#1d4ed8" ],
              "client"     => [ "👤 Cliente",    "#6b7280" ]
            }
            text, color = labels[u.role] || [ u.role, "#6b7280" ]
            span text, style: "font-weight:bold; color:#{color};"
          end
          row("Registrado") { |u| u.created_at.strftime("%d/%m/%Y") }
          if resource.stylist?
            row("Comisión %") { |u| "#{u.stylist_profile&.commission_percentage}%" }
          end
        end
      end

      column do
        if resource.client?
          attendances = resource.attendances_as_client.includes(:attendance_items).ordered.limit(20)
          orders      = resource.orders.where(status: %w[paid shipped delivered]).order(created_at: :desc).limit(20)

          panel "📊 Resumen" do
            div style: "display:grid; grid-template-columns:1fr 1fr; gap:16px; padding:4px 0 8px;" do
              div style: "text-align:center;" do
                div style: "font-size:28px; font-weight:700; color:#1d4ed8;" do
                  resource.attendances_as_client.count.to_s
                end
                div style: "font-size:11px; color:#9ca3af; text-transform:uppercase; letter-spacing:0.05em;" do
                  "Atenciones"
                end
              end
              div style: "text-align:center;" do
                div style: "font-size:28px; font-weight:700; color:#16a34a;" do
                  orders.count.to_s
                end
                div style: "font-size:11px; color:#9ca3af; text-transform:uppercase; letter-spacing:0.05em;" do
                  "Compras online"
                end
              end
            end
          end

          panel "✂️ Últimas atenciones" do
            if attendances.any?
              table_for attendances do
                column("N°")      { |a| code a.number }
                column("Fecha")   { |a| a.attended_on.strftime("%d/%m/%Y") }
                column("Items")   { |a| "#{a.attendance_items.size} item(s)" }
                column("Total")   { |a| number_to_currency(a.total_cents, unit: "$", delimiter: ".", precision: 0) }
                column("Estado")  { |a| a.status == "closed" ? status_tag("Cerrada", class: "yes") : status_tag("Abierta") }
                column("") do |a|
                  link_to "Ver", supervisor_attendance_path(a), target: "_blank",
                          style: "font-size:12px; color:#1d4ed8;"
                end
              end
            else
              div "Sin atenciones registradas.", style: "color:#9ca3af; padding:12px 0;"
            end
          end

          panel "🛍️ Compras online" do
            if orders.any?
              table_for orders do
                column("Orden")   { |o| code o.number }
                column("Fecha")   { |o| o.created_at.strftime("%d/%m/%Y") }
                column("Total")   { |o| number_to_currency(o.total_cents, unit: "$", delimiter: ".", precision: 0) }
                column("Estado")  { |o| status_tag(o.status) }
              end
            else
              div "Sin compras registradas.", style: "color:#9ca3af; padding:12px 0;"
            end
          end
        end
      end
    end
  end

  # No actualizar contraseña si se dejó en blanco al editar
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
