class CreateServicesAndAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.string :name,        null: false
      t.string :category,    null: false
      t.text :description
      t.integer :price_cents, null: false, default: 0
      t.integer :duration_minutes, null: false, default: 60
      t.boolean :active,     null: false, default: true
      t.integer :position,   null: false, default: 0

      t.timestamps
    end

    add_index :services, :category
    add_index :services, :active

    create_table :appointments do |t|
      t.references :client,  null: false, foreign_key: { to_table: :users }
      t.references :stylist, null: false, foreign_key: { to_table: :users }
      t.references :service, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at,   null: false
      t.string :status,      null: false, default: "pending"
      t.text :notes
      t.integer :price_cents, null: false, default: 0
      t.string :number,      null: false
      t.boolean :commission_paid, null: false, default: false

      t.timestamps
    end

    add_index :appointments, :starts_at
    add_index :appointments, :status
    add_index :appointments, :number, unique: true
  end
end
