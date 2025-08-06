class ChangeBalancePrecisionInWallets < ActiveRecord::Migration[8.0]
  def change
    change_column :wallets, :balance, :decimal, precision: 15, scale: 4
  end
end
