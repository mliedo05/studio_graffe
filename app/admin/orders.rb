ActiveAdmin.register Order do
  actions :index, :show

  index do
    selectable_column
    id_column
    column :number
    column(:cliente) { |o| o.user.full_name }
    column :status
    column :payment_status
    column(:total) { |o| number_to_currency(o.total_cents, unit: "$", delimiter: ".", precision: 0) }
    column :created_at
    actions
  end

  filter :status
  filter :payment_status
  filter :number_cont, label: "Número contiene"

  show do
    attributes_table do
      row :number
      row(:cliente) { |o| o.user.full_name }
      row :status
      row :payment_status
      row :payment_method
      row :transaction_id
      row(:total) { |o| number_to_currency(o.total_cents, unit: "$", delimiter: ".", precision: 0) }
      row :created_at
    end

    panel "Productos" do
      table_for order.order_items do
        column(:producto) { |i| i.product.name }
        column :quantity
        column(:precio_unitario) { |i| number_to_currency(i.unit_price_cents, unit: "$", delimiter: ".", precision: 0) }
        column(:total) { |i| number_to_currency(i.total_price_cents, unit: "$", delimiter: ".", precision: 0) }
      end
    end
  end
end
