class AddWalkInToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :walk_in, :boolean, default: false, null: false
  end
end
