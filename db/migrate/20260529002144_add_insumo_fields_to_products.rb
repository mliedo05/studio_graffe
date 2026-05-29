class AddInsumoFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :cost_per_gram_cents, :integer, default: 0, null: false
    add_column :products, :track_in_grams,      :boolean, default: false, null: false
    add_index  :products, :track_in_grams
  end
end
