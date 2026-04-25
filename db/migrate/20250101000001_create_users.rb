class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      # Devise fields
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      # Profile
      t.string :first_name, null: false
      t.string :last_name,  null: false
      t.string :phone
      t.string :role,       null: false, default: "client"

      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :role
  end
end
