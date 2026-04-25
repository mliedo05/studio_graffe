class CreateStylistProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :stylist_profiles do |t|
      t.references :stylist, null: false, foreign_key: { to_table: :users }
      t.text :bio
      t.string :specialties, array: true, default: []
      t.integer :commission_percentage, null: false, default: 35
      t.boolean :active, null: false, default: true
      t.string :instagram_handle

      t.timestamps
    end

    create_table :stylist_schedules do |t|
      t.references :stylist, null: false, foreign_key: { to_table: :users }
      t.integer :day_of_week, null: false  # 0=Sunday, 6=Saturday
      t.time :start_time,    null: false
      t.time :end_time,      null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :stylist_schedules, [ :stylist_id, :day_of_week ], unique: true

    create_table :stylist_blocked_times do |t|
      t.references :stylist, null: false, foreign_key: { to_table: :users }
      t.datetime :starts_at, null: false
      t.datetime :ends_at,   null: false
      t.string :reason

      t.timestamps
    end
  end
end
