class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :transaction_type
      t.string :from_currency
      t.string :to_currency
      t.decimal :amount
      t.decimal :result_amount

      t.timestamps
    end
  end
end
