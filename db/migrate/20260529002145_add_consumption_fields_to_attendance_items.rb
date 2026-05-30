class AddConsumptionFieldsToAttendanceItems < ActiveRecord::Migration[8.1]
  def change
    add_column    :attendance_items, :consumed_product_id, :bigint
    add_column    :attendance_items, :grams_used,          :decimal, precision: 8, scale: 2
    add_column    :attendance_items, :product_cost_cents,  :integer, default: 0, null: false
    add_column    :attendance_items, :stock_deducted,      :boolean, default: false, null: false
    add_index     :attendance_items, :consumed_product_id
    add_foreign_key :attendance_items, :products, column: :consumed_product_id
  end
end
