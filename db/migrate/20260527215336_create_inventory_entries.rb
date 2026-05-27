class CreateInventoryEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_entries do |t|
      t.references :product, null: false, foreign_key: true
      t.integer  :quantity_received,  null: false
      t.integer  :quantity_remaining, null: false
      t.integer  :unit_cost_cents,    null: false
      t.string   :supplier,           null: false
      t.string   :invoice_number,     null: false
      t.datetime :received_at,        null: false
      t.text     :notes

      t.timestamps
    end

    add_index :inventory_entries, [ :product_id, :received_at ]
  end
end
