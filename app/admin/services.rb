ActiveAdmin.register Service do
  permit_params :name, :category, :description, :price_cents, :duration_minutes, :active, :position

  index do
    selectable_column
    id_column
    column :category
    column :name
    column(:precio) { |s| number_to_currency(s.price_cents, unit: "$", delimiter: ".", precision: 0) }
    column(:duración) { |s| "#{s.duration_minutes} min" }
    column :active
    actions
  end

  filter :category
  filter :active

  form do |f|
    f.inputs "Servicio" do
      f.input :category
      f.input :name
      f.input :description
      f.input :price_cents, label: "Precio (en pesos)"
      f.input :duration_minutes, label: "Duración (minutos)"
      f.input :active
      f.input :position
    end
    f.actions
  end
end
