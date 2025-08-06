class WalletsController < ApplicationController
  before_action :set_user

  def fund
    wallet = @user.wallets.find_or_initialize_by(currency: params[:currency])
    wallet.balance ||= 0
    wallet.balance += params[:amount].to_f
    wallet.save!
    render json: wallet, status: :ok
  end

  def convert
    from = @user.wallets.find_by(currency: params[:from_currency])
    to = @user.wallets.find_or_initialize_by(currency: params[:to_currency])
    amount = params[:amount].to_f
    fx_rate = fx_rate_for(params[:from_currency], params[:to_currency])
    raise "Insufficient funds" if from.nil? || from.balance < amount

    from.balance -= amount
    to.balance ||= 0
    to.balance += (amount * fx_rate)

    from.save!
    to.save!
    render json: { from: from, to: to }, status: :ok
  end

  def withdraw
    wallet = @user.wallets.find_by(currency: params[:currency])
    amount = params[:amount].to_f
    raise "Insufficient funds" if wallet.nil? || wallet.balance < amount

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
