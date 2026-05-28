class CreateAttendancePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_payments do |t|
      t.references :attendance, null: false, foreign_key: true
      t.string  :payment_method, null: false   # cash | transfer | card | other
      t.integer :amount_cents,   null: false
      t.string  :note                          # ej: "abono", "saldo"
      t.timestamps
    end
  end
end
