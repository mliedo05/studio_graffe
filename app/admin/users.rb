ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :phone, :role, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column(:nombre) { |u| u.full_name }
    column :email
    column("Rol") { |u|
      labels = {
        "admin"      => ["⚙️ Admin",      "background:#ede9fe; color:#7c3aed"],
        "supervisor" => ["👁️ Supervisor", "background:#fef3c7; color:#d97706"],
        "stylist"    => ["✂️ Estilista",  "background:#dbeafe; color:#1d4ed8"],
        "client"     => ["👤 Cliente",    "background:#f3f4f6; color:#6b7280"]
      }
      text, style = labels[u.role] || [u.role, "background:#f3f4f6; color:#6b7280"]
      span text, style: "#{style}; padding:3px 8px; border-radius:4px; font-size:11px; font-weight:bold"
    }
    column :phone
    column :created_at
    actions
  end

  filter :role, as: :select,
         collection: User::ROLES.map { |r| [r.capitalize, r] },
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
              collection: User::ROLES.map { |r| [r.capitalize, r] }
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
