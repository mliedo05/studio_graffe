ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :phone, :role, :password, :password_confirmation,
                stylist_profile_attributes: [ :id, :commission_percentage ]

  index do
    selectable_column
    id_column
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
