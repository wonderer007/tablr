require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  
  mount Sidekiq::Web => '/sidekiq'

  # Root route - always shows landing page
  root to: 'website#index'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get '/dashboard', to: 'home#dashboard', as: :dashboard
  get '/payment/processing', to: 'payment#processing', as: :payment_processing
  get 'analytics', to: 'analytics#index'
  get 'restaurant', to: 'home#restaurant', as: :restaurant
  get 'settings', to: 'settings#edit', as: :settings
  patch 'settings/update_email_notification_period', to: 'settings#update_email_notification_period', as: :update_email_notification_period
  resources :reviews, only: [:index, :show]
  resources :complains, only: [:index]
  resources :suggestions, only: [:index]
  namespace :sentiment_analysis do
    resources :categories, only: [:index, :show]
  end
  resources :notifications, only: [] do
    member do
      patch :mark_read
    end
  end
  
  resources :demo_requests, only: [:new, :create] do
    collection do
      get :thank_you
    end
  end
end
