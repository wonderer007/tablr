require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  
  mount Sidekiq::Web => '/sidekiq'

  # Onboarding routes
  get '/onboarding', to: 'onboarding#business_name', as: :onboarding
  get '/onboarding/business-name', to: 'onboarding#business_name', as: :onboarding_business_name
  patch '/onboarding/business-name', to: 'onboarding#update_business_name'
  get '/onboarding/integrations', to: 'onboarding#integrations', as: :onboarding_integrations
  post '/onboarding/integrations', to: 'onboarding#select_integration'
  get '/onboarding/integration-url', to: 'onboarding#integration_url', as: :onboarding_integration_url
  patch '/onboarding/integration-url', to: 'onboarding#save_integration_url'
  get '/onboarding/complete', to: 'onboarding#complete', as: :onboarding_complete

  # Root route - always shows landing page
  root to: 'website#index'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get '/business/:id/report', to: 'businesses#report', as: :report
  get '/dashboard', to: 'home#dashboard', as: :dashboard
  get '/payment/processing', to: 'payment#processing', as: :payment_processing
  get '/data/processing', to: 'home#data_processing', as: :data_processing
  post '/webhooks/lemonsqueezy', to: 'payment#lemonsqueezy_webhook', as: :lemonsqueezy_webhook
  get 'restaurant', to: 'home#restaurant', as: :restaurant
  get 'settings', to: 'settings#edit', as: :settings
  get 'support', to: 'support#index', as: :support
  patch 'settings/update_email_notification_period', to: 'settings#update_email_notification_period', as: :update_email_notification_period
  resources :complains, only: [:index]
  resources :suggestions, only: [:index]

  resources :demo_requests, only: [:new, :create] do
    collection do
      get :thank_you
    end
  end

  get '/unsubscribe', to: 'website#unsubscribe', as: :unsubscribe
end
