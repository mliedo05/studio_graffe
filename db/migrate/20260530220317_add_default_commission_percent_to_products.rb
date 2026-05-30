class AddDefaultCommissionPercentToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :default_commission_percent, :integer, default: 10, null: false
  end
end
