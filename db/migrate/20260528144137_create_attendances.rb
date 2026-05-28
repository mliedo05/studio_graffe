class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances do |t|
      # Número correlativo: "20260528-001" — único y autoincremental por día
      t.string :number, null: false

      # Cliente — puede ser registrado o walk-in
      t.references :client, foreign_key: { to_table: :users }, null: true
      t.string :client_name  # nombre libre para walk-in

      # Quién registra la atención
      t.references :registered_by, foreign_key: { to_table: :users }, null: false

      t.date    :attended_on, null: false   # fecha de la atención
      t.text    :notes
      t.integer :total_cents,     default: 0, null: false
      t.integer :paid_cents,      default: 0, null: false  # suma de todos los pagos
      t.string  :status, default: "open", null: false      # open | closed

      t.timestamps
    end

    add_index :attendances, :number, unique: true
    add_index :attendances, :attended_on
    add_index :attendances, :status
  end
end
