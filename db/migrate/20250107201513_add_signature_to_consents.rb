class AddSignatureToConsents < ActiveRecord::Migration[6.1]
  def change
    add_column :consents, :signature, :binary
  end
end
