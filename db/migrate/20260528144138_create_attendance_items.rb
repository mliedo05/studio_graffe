class CreateAttendanceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_items do |t|
      t.references :attendance, null: false, foreign_key: true
      t.references :stylist,    null: false, foreign_key: { to_table: :users }

      # Puede ser un servicio o un producto
      t.string :item_type, null: false       # "service" | "product"
      t.references :service, foreign_key: true, null: true
      t.references :product, foreign_key: true, null: true
      t.string  :description, null: false     # nombre descriptivo (por si se borra el servicio)

      t.integer :price_cents,      null: false
      t.integer :commission_percent, null: false  # editable por ítem
      t.integer :commission_cents,   null: false, default: 0

      t.timestamps
    end

    add_index :attendance_items, :item_type
  end
end
