require 'rails_helper'

RSpec.describe "RSpec Installation Validation" do
  it "validates that RSpec is correctly installed and configured" do
    expect(true).to be true
  end

  it "validates Rails environment is test" do
    expect(Rails.env).to eq('test')
  end

  it "validates ActiveRecord is available" do
    expect(defined?(ActiveRecord)).to be_truthy
  end
end
