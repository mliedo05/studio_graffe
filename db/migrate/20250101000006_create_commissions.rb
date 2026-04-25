class CreateCommissions < ActiveRecord::Migration[8.1]
  def change
    create_table :commissions do |t|
      t.references :stylist,     null: false, foreign_key: { to_table: :users }
      t.references :appointment, null: false, foreign_key: true
      t.integer :amount_cents,   null: false, default: 0
      t.integer :percentage,     null: false
      t.string :status,          null: false, default: "pending"
      t.datetime :paid_at

      t.timestamps
    end

    add_index :commissions, :status
  end
end
