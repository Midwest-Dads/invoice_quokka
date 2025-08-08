Rails.application.routes.draw do
  # Email authentication routes
  resource :session, only: [:new, :create, :destroy], controller: 'email/sessions'
  resource :registration, only: [:new, :create], controller: 'email/registrations'
  resources :passwords, param: :token, controller: 'email/passwords'
  
  # Application routes
  get "dashboard/index"
  root to: 'dashboard#index'
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
