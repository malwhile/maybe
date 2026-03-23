class AddLargeTransactionThresholdToFamilies < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :large_transaction_threshold, :decimal, precision: 19, scale: 4
  end
end
