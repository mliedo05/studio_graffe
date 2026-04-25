ActiveAdmin.register Appointment do
  actions :index, :show, :edit, :update

  permit_params :status, :notes

  index do
    selectable_column
    id_column
    column :number
    column(:cliente) { |a| a.client.full_name }
    column(:estilista) { |a| a.stylist.full_name }
    column(:servicio) { |a| a.service.name }
    column :starts_at
    column :status
    column(:precio) { |a| number_to_currency(a.price_cents, unit: "$", delimiter: ".", precision: 0) }
    actions
  end

  filter :status
  filter :starts_at_gteq, label: "Desde"
  filter :starts_at_lteq, label: "Hasta"

  form do |f|
    f.inputs "Cita" do
      f.input :status, as: :select, collection: Appointment::STATUSES
      f.input :notes
    end
    f.actions
  end
end
