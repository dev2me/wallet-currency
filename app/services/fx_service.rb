class FxService
  RATES = {
    "USD" => { "MXN" => 18.70 },
    "MXN" => { "USD" => 0.053 }
  }.freeze

  def self.convert(from_currency, to_currency, amount)
    raise ArgumentError, "Amount must be positive" if amount <= 0
    raise ArgumentError, "Invalid currency: #{from_currency}" unless RATES.key?(from_currency)
    raise ArgumentError, "Invalid currency: #{to_currency}" unless RATES[from_currency]&.key?(to_currency)

    rate = RATES.dig(from_currency, to_currency)
    raise ArgumentError, "FX rate not found" unless rate

    BigDecimal(amount) * BigDecimal(rate.to_s)
  end
end
