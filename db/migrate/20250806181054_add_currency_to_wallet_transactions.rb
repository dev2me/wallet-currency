class AddCurrencyToWalletTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :wallet_transactions, :currency, :string, null: true
  end
end
