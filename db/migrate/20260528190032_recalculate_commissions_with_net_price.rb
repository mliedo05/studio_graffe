class RecalculateCommissionsWithNetPrice < ActiveRecord::Migration[8.1]
  def up
    # Recalcula commission_cents sobre el neto (sin IVA 19%) para todos los ítems existentes
    execute <<~SQL
      UPDATE attendance_items
      SET commission_cents = ROUND(ROUND(price_cents / 1.19) * commission_percent / 100.0)
    SQL
  end

  def down
    execute <<~SQL
      UPDATE attendance_items
      SET commission_cents = ROUND(price_cents * commission_percent / 100.0)
    SQL
  end
end
