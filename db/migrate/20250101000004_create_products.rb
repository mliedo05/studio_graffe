class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :product_categories do |t|
      t.string :name,        null: false
      t.string :slug,        null: false
      t.text :description
      t.boolean :active,     null: false, default: true
      t.integer :position,   null: false, default: 0

      t.timestamps
    end

    add_index :product_categories, :slug, unique: true

    create_table :products do |t|
      t.references :product_category, null: false, foreign_key: true
      t.string :name,        null: false
      t.string :brand,       null: false
      t.string :slug,        null: false
      t.text :description
      t.string :sku
      t.integer :price_cents, null: false, default: 0
      t.integer :stock_quantity, null: false, default: 0
      t.boolean :featured,   null: false, default: false
      t.boolean :active,     null: false, default: true
      t.integer :position,   null: false, default: 0

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :featured
    add_index :products, :active
  end
end
