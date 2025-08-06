class Wallet < ApplicationRecord
  belongs_to :user

  validates :currency, presence: true
  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  def self.for(user, currency)
    find_or_initialize_by(user: user, currency: currency) do |wallet|
      wallet.balance = 0
    end
  end
end
