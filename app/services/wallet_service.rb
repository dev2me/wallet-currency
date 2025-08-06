class WalletService
  def self.fund(user:, currency:, amount:)
    wallet = user.wallets.find_or_initialize_by(currency: currency)
    wallet.balance ||= 0
    wallet.balance += amount
    wallet.save!

    user.wallet_transactions.create!(
      transaction_type: :fund,
      currency: currency,
      amount: amount
    )

    wallet
  end

  def self.withdraw(user:, currency:, amount:)
    wallet = user.wallets.find_by(currency: currency)
    current_balance = wallet&.balance || 0
    raise ArgumentError, "Insufficient funds in #{currency} wallet" if current_balance < amount

    wallet.balance = current_balance - amount
    wallet.save!

    user.wallet_transactions.create!(
      transaction_type: :withdraw,
      currency: currency,
      amount: amount
    )

    wallet
  end

  def self.convert(user:, from_currency:, to_currency:, amount:)
    from_wallet = user.wallets.find_or_initialize_by(currency: from_currency)
    from_balance = from_wallet&.balance || 0
    raise ArgumentError, "Insufficient funds in #{from_currency} wallet" if from_balance < amount

    converted = FxService.convert(from_currency, to_currency, amount)

    to_wallet = user.wallets.find_or_initialize_by(currency: to_currency)
    to_wallet.balance ||= 0

    ActiveRecord::Base.transaction do
      from_wallet.balance ||= 0
      from_wallet.balance -= amount
      from_wallet.save!

      to_wallet.balance += converted
      to_wallet.save!

      user.wallet_transactions.create!(
        transaction_type: :convert,
        from_currency: from_currency,
        to_currency: to_currency,
        amount: amount,
        result_amount: converted
      )
    end

    { from: from_wallet, to: to_wallet }
  end
end
