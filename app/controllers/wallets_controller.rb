class WalletsController < ApplicationController
  before_action :set_user

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ArgumentError, with: :handle_bad_request

  def fund
    amount = validate_amount(params[:amount])
    currency = validate_currency(params[:currency])

    wallet = WalletService.fund(user: @user, currency: currency, amount: amount)
    render json: wallet, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Validation failed: #{e.message}" }, status: :unprocessable_entity
  end

  def convert
    amount = validate_amount(params[:amount])
    from_currency = validate_currency(params[:from_currency])
    to_currency = validate_currency(params[:to_currency])

    return render_same_currency_error if from_currency == to_currency

    result = WalletService.convert(
      user: @user,
      from_currency: from_currency,
      to_currency: to_currency,
      amount: amount
    )

    render json: result, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Transaction failed: #{e.message}" }, status: :unprocessable_entity
  rescue => e
    render json: { error: "Conversion failed: #{e.message}" }, status: :bad_request
  end

  def withdraw
    amount = validate_amount(params[:amount])
    currency = validate_currency(params[:currency])

    wallet = WalletService.withdraw(user: @user, currency: currency, amount: amount)
    render json: wallet, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Withdrawal failed: #{e.message}" }, status: :unprocessable_entity
  end

  def balances
    balances = @user.wallets.pluck(:currency, :balance).to_h
    render json: balances, status: :ok
  end

  def transactions
    render json: @user.wallet_transactions.order(created_at: :desc), status: :ok
  end

  def reconciliation
    expected_balances = Hash.new(0)
    # FUND
    @user.wallet_transactions.fund.group(:currency).sum(:amount).each do |currency, amount|
      next if currency.blank?
      expected_balances[currency] += amount
    end

    # WITHDRAW
    @user.wallet_transactions.withdraw.group(:currency).sum(:amount).each do |currency, amount|
      next if currency.blank?
      expected_balances[currency] -= amount
    end

    # CONVERT: resta from
    @user.wallet_transactions.convert.group(:from_currency).sum(:amount).each do |currency, amount|
      next if currency.blank?
      expected_balances[currency] -= amount
    end

    # CONVERT: suma to
    @user.wallet_transactions.convert.group(:to_currency).sum(:result_amount).each do |currency, amount|
      next if currency.blank?
      expected_balances[currency] += amount
    end

    current_balances = @user.wallets.pluck(:currency, :balance).to_h
    expected_balances.transform_values! { |v| v.round(2) }

    ok = expected_balances.all? do |currency, expected|
      current = current_balances[currency].to_f.round(2)
      expected == current
    end

    render json: {
      expected_balances: expected_balances,
      current_balances: current_balances.transform_values { |v| v.to_f.round(2) },
      ok: ok
    }, status: :ok
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def validate_amount(amount_param)
    raise ArgumentError, "Amount is required" if amount_param.blank?

    amount = BigDecimal(amount_param.to_s)
    raise ArgumentError, "Amount must be positive" if amount <= 0
    raise ArgumentError, "Amount is too large" if amount > BigDecimal("999999999.99")

    amount
  rescue ArgumentError => e
    raise e
  rescue => e
    raise ArgumentError, "Invalid amount format"
  end

  def validate_currency(currency_param)
    raise ArgumentError, "Currency is required" if currency_param.blank?

    currency = currency_param.to_s.upcase
    valid_currencies = %w[USD MXN]

    raise ArgumentError, "Unsupported currency: #{currency}. Supported currencies: #{valid_currencies.join(', ')}" unless valid_currencies.include?(currency)

    currency
  end

  def render_insufficient_funds(currency)
    render json: {
      error: "Insufficient funds in #{currency} wallet",
      error_code: "INSUFFICIENT_FUNDS",
      currency: currency
    }, status: :unprocessable_entity
  end

  def render_same_currency_error
    render json: {
      error: "Cannot convert between the same currency",
      error_code: "SAME_CURRENCY_CONVERSION"
    }, status: :bad_request
  end

  def handle_not_found(exception)
    render json: {
      error: "User not found",
      error_code: "USER_NOT_FOUND"
    }, status: :not_found
  end

  def handle_bad_request(exception)
    render json: {
      error: exception.message,
      error_code: "BAD_REQUEST"
    }, status: :bad_request
  end

  def handle_standard_error(exception)
    Rails.logger.error "Unexpected error in WalletsController: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    render json: {
      error: "An unexpected error occurred",
      error_code: "INTERNAL_ERROR"
    }, status: :internal_server_error
  end
end
