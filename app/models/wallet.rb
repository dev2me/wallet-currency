class Wallet < ApplicationRecord
  belongs_to :user

  validates :currency, presence: true
  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  def self.for(user, currency)
    user.wallets.find_or_initialize_by(currency: currency)
  end
end
