Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations'
  }


  resources :reminders
  resources :notes
resources :profiles, only: [:show, :edit, :update]
resources :notifications, only: [:index, :create]




end
