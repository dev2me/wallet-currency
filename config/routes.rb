Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :wallets, only: [] do
    member do
      post :fund
      post :convert
      post :withdraw
      get :balances
    end
  end
end
