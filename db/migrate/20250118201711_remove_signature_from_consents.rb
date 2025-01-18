class RemoveSignatureFromConsents < ActiveRecord::Migration[6.1]
  def change
    remove_column :consents, :signature, :bytea
  end
end
