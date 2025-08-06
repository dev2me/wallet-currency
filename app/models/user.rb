class User < ApplicationRecord
  has_many :wallets, dependent: :destroy
end
