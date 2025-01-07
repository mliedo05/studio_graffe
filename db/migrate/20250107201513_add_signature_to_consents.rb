class AddSignatureToConsents < ActiveRecord::Migration[6.1]
  def change
    add_column :consents, :signature, :text
  end
end
