class WalletsController < ApplicationController
  before_action :set_user

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ArgumentError, with: :handle_bad_request

  def fund
    amount = validate_amount(params[:amount])
    currency = validate_currency(params[:currency])

    wallet = Wallet.for(@user, currency)
    wallet.balance ||= 0
    wallet.balance += amount
    wallet.save!

    @user.wallet_transactions.create!(
      transaction_type: :fund,
      currency: wallet.currency,
      amount: amount
    )

    render json: wallet, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Validation failed: #{e.message}" }, status: :unprocessable_entity
  end

  def convert
    amount = validate_amount(params[:amount])
    from_currency = validate_currency(params[:from_currency])
    to_currency = validate_currency(params[:to_currency])

    return render_same_currency_error if from_currency == to_currency

    from_wallet = Wallet.for(@user, from_currency)
    to_wallet = Wallet.for(@user, to_currency)

    # Verificar fondos suficientes
    from_balance = from_wallet&.balance || 0
    return render_insufficient_funds(from_currency) if from_balance < amount

    converted = FxService.convert(from_currency, to_currency, amount)

    # Asegurar que ambos wallets existen y tienen balance inicializado
    from_wallet.balance ||= 0
    from_wallet.balance -= amount

    to_wallet.balance ||= 0
    to_wallet.balance += converted

    ActiveRecord::Base.transaction do
      from_wallet.save!
      to_wallet.save!
      @user.wallet_transactions.create!(
        transaction_type: :convert,
        from_currency: from_currency,
        to_currency: to_currency,
        amount: amount,
        result_amount: converted
      )
    end

    render json: { from: from_wallet, to: to_wallet }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Transaction failed: #{e.message}" }, status: :unprocessable_entity
  rescue => e
    render json: { error: "Conversion failed: #{e.message}" }, status: :bad_request
  end

  def withdraw
    amount = validate_amount(params[:amount])
    currency = validate_currency(params[:currency])

    wallet = Wallet.for(@user, currency)

    # Verificar que el wallet existe y tiene balance suficiente
    current_balance = wallet&.balance || 0
    return render_insufficient_funds(currency) if current_balance < amount

    wallet.balance = current_balance - amount
    wallet.save!

    @user.wallet_transactions.create!(
      transaction_type: :withdraw,
      currency: wallet.currency,
      amount: amount
    )

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
    balances = @user.wallets.sum(:balance)
    net = @user.wallet_transactions.sum("CASE WHEN transaction_type = 0 THEN amount WHEN transaction_type = 2 THEN -amount ELSE 0 END")

    render json: {
      net_funding_minus_withdrawals: net.to_f,
      current_balance: balances.to_f,
      ok: net.to_f.round(2) == balances.to_f.round(2)
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
