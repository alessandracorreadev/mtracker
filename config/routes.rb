Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "dashboard", to: "pages#index"
  get "settings", to: "settings#index", as: :settings
  get "settings/theme", to: "settings#theme", as: :settings_theme
  get "settings/password", to: "settings#password", as: :settings_password
  patch "settings/password", to: "settings#update_password", as: :update_settings_password
  get "settings/email", to: "settings#email", as: :settings_email
  patch "settings/email", to: "settings#update_email", as: :update_settings_email
  get "settings/support", to: "settings#support", as: :settings_support
  resources :goals
  resources :expenses
  resources :incomes
  resources :investments do
    get :returns, on: :collection
  end
  resources :chats, only: [:index, :show, :create, :destroy] do
    resources :messages, only: [:create]
    namespace :wizard do
      resources :expenses, only: [:new, :create, :destroy]
      resources :incomes, only: [:new, :create, :destroy]
      resources :investments, only: [:new, :create, :destroy]
    end
  end
  # Defines the root path route ("/")
  # root "posts#index"
end
