Rails.application.routes.draw do
  devise_for :users
  
  # Contact/Pre-registration routes
  resources :contact, only: [:new, :create]
  
  # Root route - contact page for unauthenticated users, dashboard for authenticated users
  authenticated :user do
    root to: 'home#dashboard', as: :authenticated_root
  end
  
  root to: 'contact#new'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get '/dashboard', to: 'home#dashboard', as: :dashboard
  get 'analytics', to: 'analytics#index'
  get 'restaurant', to: 'home#restaurant', as: :restaurant
  resources :reviews, only: [:index, :show]
  resources :complains, only: [:index]
  resources :suggestions, only: [:index]
  namespace :sentiment_analysis do
    resources :categories, only: [:index, :show]
  end
end
