require 'rails_helper'

RSpec.describe WalletTransaction, type: :model do
  let(:user) { User.create!(name: 'Test User') }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'enums' do
    it { should define_enum_for(:transaction_type).with_values(fund: 0, convert: 1, withdraw: 2) }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount) }

    context 'when transaction_type is fund' do
      subject { described_class.new(user: user, transaction_type: :fund, amount: 100) }

      it { should validate_presence_of(:currency) }
      it { should_not validate_presence_of(:from_currency) }
      it { should_not validate_presence_of(:to_currency) }
    end

    context 'when transaction_type is withdraw' do
      subject { described_class.new(user: user, transaction_type: :withdraw, amount: 100) }

      it { should validate_presence_of(:currency) }
      it { should_not validate_presence_of(:from_currency) }
      it { should_not validate_presence_of(:to_currency) }
    end

    context 'when transaction_type is convert' do
      subject { described_class.new(user: user, transaction_type: :convert, amount: 100) }

      it { should validate_presence_of(:from_currency) }
      it { should validate_presence_of(:to_currency) }
      it { should_not validate_presence_of(:currency) }
    end
  end

  describe 'creating transactions' do
    context 'fund transaction' do
      it 'creates a valid fund transaction' do
        transaction = WalletTransaction.create!(
          user: user,
          transaction_type: :fund,
          currency: 'USD',
          amount: 100.50
        )

        expect(transaction).to be_persisted
        expect(transaction.fund?).to be true
        expect(transaction.currency).to eq('USD')
        expect(transaction.amount).to eq(100.50)
        expect(transaction.user).to eq(user)
      end

      it 'fails without currency' do
        transaction = WalletTransaction.new(
          user: user,
          transaction_type: :fund,
          amount: 100
        )

        expect(transaction).not_to be_valid
        expect(transaction.errors[:currency]).to include("can't be blank")
      end
    end

    context 'withdraw transaction' do
      it 'creates a valid withdraw transaction' do
        transaction = WalletTransaction.create!(
          user: user,
          transaction_type: :withdraw,
          currency: 'MXN',
          amount: 500.25
        )

        expect(transaction).to be_persisted
        expect(transaction.withdraw?).to be true
        expect(transaction.currency).to eq('MXN')
        expect(transaction.amount).to eq(500.25)
      end

      it 'fails without currency' do
        transaction = WalletTransaction.new(
          user: user,
          transaction_type: :withdraw,
          amount: 100
        )

        expect(transaction).not_to be_valid
        expect(transaction.errors[:currency]).to include("can't be blank")
      end
    end

    context 'convert transaction' do
      it 'creates a valid convert transaction' do
        transaction = WalletTransaction.create!(
          user: user,
          transaction_type: :convert,
          from_currency: 'USD',
          to_currency: 'MXN',
          amount: 100,
          result_amount: 1870
        )

        expect(transaction).to be_persisted
        expect(transaction.convert?).to be true
        expect(transaction.from_currency).to eq('USD')
        expect(transaction.to_currency).to eq('MXN')
        expect(transaction.amount).to eq(100)
        expect(transaction.result_amount).to eq(1870)
      end

      it 'fails without from_currency' do
        transaction = WalletTransaction.new(
          user: user,
          transaction_type: :convert,
          to_currency: 'MXN',
          amount: 100
        )

        expect(transaction).not_to be_valid
        expect(transaction.errors[:from_currency]).to include("can't be blank")
      end

      it 'fails without to_currency' do
        transaction = WalletTransaction.new(
          user: user,
          transaction_type: :convert,
          from_currency: 'USD',
          amount: 100
        )

        expect(transaction).not_to be_valid
        expect(transaction.errors[:to_currency]).to include("can't be blank")
      end
    end
  end

  describe 'edge cases' do
    it 'fails without amount' do
      transaction = WalletTransaction.new(
        user: user,
        transaction_type: :fund,
        currency: 'USD'
      )

      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount]).to include("can't be blank")
    end

    it 'fails without user' do
      transaction = WalletTransaction.new(
        transaction_type: :fund,
        currency: 'USD',
        amount: 100
      )

      expect(transaction).not_to be_valid
      expect(transaction.errors[:user]).to include("must exist")
    end

    it 'allows decimal amounts' do
      transaction = WalletTransaction.create!(
        user: user,
        transaction_type: :fund,
        currency: 'USD',
        amount: 99.9999
      )

      expect(transaction.amount).to eq(99.9999)
    end
  end

  describe 'scopes and queries' do
    before do
      WalletTransaction.create!(user: user, transaction_type: :fund, currency: 'USD', amount: 100)
      WalletTransaction.create!(user: user, transaction_type: :withdraw, currency: 'USD', amount: 50)
      WalletTransaction.create!(user: user, transaction_type: :convert, from_currency: 'USD', to_currency: 'MXN', amount: 25, result_amount: 467.5)
    end

    it 'can filter by transaction type' do
      expect(WalletTransaction.fund.count).to eq(1)
      expect(WalletTransaction.withdraw.count).to eq(1)
      expect(WalletTransaction.convert.count).to eq(1)
    end

    it 'can find transactions for a specific user' do
      other_user = User.create!(name: 'Other User')
      WalletTransaction.create!(user: other_user, transaction_type: :fund, currency: 'USD', amount: 200)

      expect(user.wallet_transactions.count).to eq(3)
      expect(other_user.wallet_transactions.count).to eq(1)
    end
  end
end
