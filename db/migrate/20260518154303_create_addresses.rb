class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :label,          null: false, default: "Mi dirección"
      t.string  :recipient_name, null: false
      t.string  :phone,          null: false
      t.string  :region,         null: false
      t.string  :comuna,         null: false
      t.string  :city,           null: false
      t.string  :street,         null: false
      t.string  :street_number,  null: false
      t.string  :apartment
      t.boolean :default,        null: false, default: false

      t.timestamps
    end

    add_index :addresses, [ :user_id, :default ]
  end
end
