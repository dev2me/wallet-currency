require 'rails_helper'

RSpec.describe FxService do
  it "converts USD to MXN" do
    result = FxService.convert("USD", "MXN", 100)
    expect(result).to eq(1870)
  end

  it "raises error for unsupported pair" do
    expect { FxService.convert("USD", "EUR", 100) }.to raise_error(ArgumentError)
  end
end
