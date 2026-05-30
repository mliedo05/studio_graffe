ActiveAdmin.register Service do
  permit_params :name, :category, :description, :price_cents, :duration_minutes,
                :active, :position, :default_commission_percent

  index do
    selectable_column
    id_column
    column :category
    column :name
    column("Precio") { |s| number_to_currency(s.price_cents, unit: "$", delimiter: ".", precision: 0) }
    column("Duración") { |s| "#{s.duration_minutes} min" }
    column("Comisión %") do |s|
      span "#{s.default_commission_percent}%",
           style: "font-weight:bold; color:#7c3aed; background:#ede9fe; padding:2px 8px; border-radius:4px; font-size:12px;"
    end
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
      f.input :price_cents,    label: "Precio (en pesos)"
      f.input :duration_minutes, label: "Duración (minutos)"
      f.input :default_commission_percent,
              label: "Comisión por defecto (%)",
              hint:  "Porcentaje que se pre-carga al registrar este servicio en una atención. El supervisor puede ajustarlo por ítem."
      f.input :active
      f.input :position
    end
    f.actions
  end
end
