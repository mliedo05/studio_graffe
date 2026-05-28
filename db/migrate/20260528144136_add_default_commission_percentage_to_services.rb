class AddDefaultCommissionPercentageToServices < ActiveRecord::Migration[8.1]
  def change
    add_column :services, :default_commission_percent, :integer, default: 40, null: false
  end
end
