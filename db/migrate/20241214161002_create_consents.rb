class CreateConsents < ActiveRecord::Migration[6.1]
  def change
    create_table :consents do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.integer :document_type
      t.string :document_number
      t.string :phone_number
      t.text :professional_diagnosis
      t.text :professional_observations
      t.boolean :procedure_authorization
      t.boolean :procedure_acknowledgement
      t.boolean :diagnosis_confirmation
      t.boolean :image_use_authorization
      t.boolean :service_cost_acceptance
      t.boolean :informed_consent_acceptance
      t.boolean :is_adult

      t.timestamps
    end
  end
end
