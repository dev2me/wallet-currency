class WalletTransaction < ApplicationRecord
  belongs_to :user
  enum :transaction_type, { fund: 0, convert: 1, withdraw: 2 }
  validates :amount, presence: true
  validates :from_currency, presence: true, if: -> { convert? }
  validates :to_currency, presence: true, if: -> { convert? }
  validates :currency, presence: true, if: -> { fund? || withdraw? }
end
