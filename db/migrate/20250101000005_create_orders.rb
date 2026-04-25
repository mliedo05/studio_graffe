class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :number,        null: false
      t.string :status,        null: false, default: "cart"
      t.string :payment_status, null: false, default: "pending"
      t.string :payment_method
      t.string :payment_token
      t.string :transaction_id
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :total_cents,    null: false, default: 0

      t.timestamps
    end

    add_index :orders, :number, unique: true
    add_index :orders, :status
    add_index :orders, :payment_status

    create_table :order_items do |t|
      t.references :order,   null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity,   null: false, default: 1
      t.integer :unit_price_cents, null: false, default: 0
      t.integer :total_price_cents, null: false, default: 0

      t.timestamps
    end
  end
end
