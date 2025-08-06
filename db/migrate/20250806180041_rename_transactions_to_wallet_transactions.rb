class RenameTransactionsToWalletTransactions < ActiveRecord::Migration[8.0]
  def change
    rename_table :transactions, :wallet_transactions
  end
end
