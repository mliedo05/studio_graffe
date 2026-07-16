class CreateAttendanceTechnicalSheets < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_technical_sheets do |t|
      t.references :attendance, null: false, foreign_key: true
      t.string :technique
      t.string :tint_brand
      t.text :tint_formula
      t.boolean :decolorization_applied
      t.string :decolorization_height
      t.integer :decolorization_level_start
      t.integer :decolorization_level_achieved
      t.string :hair_elasticity
      t.string :hair_porosity
      t.text :notes

      t.timestamps
    end
  end
end
