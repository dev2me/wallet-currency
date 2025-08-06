class User < ApplicationRecord
  has_many :wallets, dependent: :destroy
  has_many :wallet_transactions, dependent: :destroy
end
