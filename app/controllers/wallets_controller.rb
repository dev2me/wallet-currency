class WalletsController < ApplicationController
  before_action :set_user

  def fund
    wallet = Wallet.for(@user, params[:currency])
    wallet.balance ||= 0
    wallet.balance += BigDecimal(params[:amount].to_s)
    wallet.save!
    render json: wallet, status: :ok
  end

  def convert
    amount = BigDecimal(params[:amount].to_s)
    from_wallet = Wallet.for(@user, params[:from_currency])
    to_wallet = Wallet.for(@user, params[:to_currency])

    raise "Insufficient funds" if from_wallet.balance < amount

    converted = FxService.convert(params[:from_currency], params[:to_currency], amount)

    from_wallet.balance -= amount
    to_wallet.balance ||= 0
    to_wallet.balance += converted

    from_wallet.save!
    to_wallet.save!
    render json: { from: from_wallet, to: to_wallet }, status: :ok
  end

  def withdraw
    wallet = Wallet.for(@user, params[:currency])
    amount = BigDecimal(params[:amount].to_s)
    raise "Insufficient funds" if wallet.balance < amount

    wallet.balance -= amount
    wallet.save!
    render json: wallet, status: :ok
  end

  def balances
    balances = @user.wallets.pluck(:currency, :balance).to_h
    render json: balances, status: :ok
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def fx_rate_for(from, to)
    rates = {
      "USD" => { "MXN" => 18.70 },
      "MXN" => { "USD" => 0.053 }
    }
    rates[from][to] || raise("FX rate not found")
  end
end
