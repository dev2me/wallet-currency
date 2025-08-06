require 'rails_helper'

RSpec.describe Wallet, type: :model do
  let(:user) { User.create!(name: 'Test User') }

  it { should belong_to(:user) }

  it { should validate_presence_of(:currency) }

  describe 'balance validation' do
    it 'validates presence of balance (via numericality validation)' do
      wallet = Wallet.new(user: user, currency: 'USD', balance: nil)
      expect(wallet).not_to be_valid
      expect(wallet.errors[:balance]).to include("is not a number")
    end

    it 'validates balance is a number' do
      wallet = Wallet.new(user: user, currency: 'USD', balance: 'invalid')
      expect(wallet).not_to be_valid
      expect(wallet.errors[:balance]).to include("is not a number")
    end
  end

  it "does not allow negative balances" do
    wallet = Wallet.new(user: user, currency: "USD", balance: -100)
    expect(wallet).not_to be_valid
  end

  it "creates a valid wallet with valid attributes" do
    wallet = Wallet.new(user: user, currency: "USD", balance: 100.0)
    expect(wallet).to be_valid
  end
end
