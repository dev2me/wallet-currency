require 'rails_helper'

RSpec.describe Wallet, type: :request do
  let(:user) { User.create!(name: "Fernando") }

  describe "POST /wallets/:user_id/fund" do
    it "funds the wallet with given amount" do
      post "wallets/#{user.id}/fund", params: { amount: 1000, currency: "USD" }
      expect(response).to have_http_status(:success)
      expect(user.wallets.find_by(currency: "USD").balance).to eq(1000)
    end
  end

  describe "POST /wallets/:user_id/convert" do
    it "converts currency using hardcoded rates" do
      user.wallets.create!(currency: "USD", balance: 1000)
      post "/wallets/#{user.id}/convert", params: { from_currency: "USD", to_currency: "MXN", amount: 500 }
      expect(response).to have_http_status(:success)
      expect(user.wallets.find_by(currency: "USD").balance).to eq(500)
      expect(user.wallets.find_by(currency: "MXN").balance).to eq(9350) # 500 * 18.7
    end
  end

  describe "POST /wallets/:user_id/withdraw" do
    it "withdraws amount from wallet" do
      user.wallets.create!(currency: "MXN", balance: 1000)
      post "/wallets/#{user.id}/withdraw", params: { currency: "MXN", amount: 300 }
      expect(response).to have_http_status(:success)
      expect(user.wallets.find_by(currency: "MXN").balance).to eq(700)
    end
  end

  describe "GET /wallets/:user_id/balances" do
    it "returns the current balances" do
      user.wallets.create!(currency: "USD", balance: 200)
      user.wallets.create!(currency: "MXN", balance: 500)
      get "/wallets/#{user.id}/balances"
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to eq({ "USD" => 200, "MXN" => 500 })
    end
  end
end
