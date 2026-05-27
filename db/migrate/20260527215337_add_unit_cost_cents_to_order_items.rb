class AddUnitCostCentsToOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :order_items, :unit_cost_cents,       :integer
    add_column :order_items, :total_cost_cents,      :integer
  end
end
