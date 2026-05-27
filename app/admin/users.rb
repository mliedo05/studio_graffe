ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :phone, :role

  index do
    selectable_column
    id_column
    column(:nombre) { |u| u.full_name }
    column :email
    column :role
    column :phone
    column :created_at
    actions
  end

  filter :role, as: :select, collection: User::ROLES
  filter :email_cont, label: "Email contiene"

  form do |f|
    f.inputs "Usuario" do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :phone
      f.input :role, as: :select, collection: User::ROLES
    end
    f.actions
  end
end
