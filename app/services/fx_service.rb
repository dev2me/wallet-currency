class FxService
  RATES = {
    "USD" => { "MXN" => 18.70 },
    "MXN" => { "USD" => 0.053 }
  }.freeze

  def self.convert(from_currency, to_currency, amount)
    rate = RATES.dig(from_currency, to_currency)
    raise ArgumentError, "FX rate not found" unless rate

    BigDecimal(amount) * BigDecimal(rate.to_s)
  end
end
