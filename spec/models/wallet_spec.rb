require 'rails_helper'

RSpec.describe Wallet, type: :model do
  it { should belong_to(:user) }
  it { should validate_presence_of(:currency) }
  it { should validate_presence_of(:balance) }

  it "does not allow negative balances" do
    wallet = Wallet.new(currency: "USD", balance: -100)
    expect(wallet).not_to be_valid
  end
end
