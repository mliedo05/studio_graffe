class AddCheckoutFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    # ── Facturación ──────────────────────────────────────────────
    add_column :orders, :billing_first_name,     :string
    add_column :orders, :billing_last_name,      :string
    add_column :orders, :billing_document_type,  :string  # rut | passport | dni
    add_column :orders, :billing_document_number, :string
    add_column :orders, :billing_email,          :string
    add_column :orders, :billing_phone,          :string

    # ── Envío ─────────────────────────────────────────────────────
    add_column :orders, :shipping_type,           :string, default: "pickup"  # pickup | delivery
    add_column :orders, :shipping_recipient_name, :string
    add_column :orders, :shipping_phone,          :string
    add_column :orders, :shipping_region,         :string
    add_column :orders, :shipping_comuna,         :string
    add_column :orders, :shipping_city,           :string
    add_column :orders, :shipping_street,         :string
    add_column :orders, :shipping_street_number,  :string
    add_column :orders, :shipping_apartment,      :string

    add_index :orders, :shipping_type
  end
end
