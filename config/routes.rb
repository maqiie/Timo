
Rails.application.routes.draw do
  # Routes for organizations
  get 'organizations/show'
  get 'organizations/add_worker'
  resources :organizations do
    resources :memberships, only: [:create]
  end

  # ActionCable endpoint
  mount ActionCable.server => '/cable'

  # Devise Token Auth routes
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations',
    sessions: 'auth/sessions'
  }

  # Custom route for updating user via PATCH
  patch '/auth', to: 'auth/registrations#update'

  # Routes for reminders
  resources :reminders do
    collection do
      get 'index_by_date'
    end
    member do
      patch 'complete'
      patch 'update' # Adding the route to update a reminder (task)
      get :special_events
      post 'add_user'
      put 'complete'
    end
  end

  # Routes for friend requests
  resources :friend_requests, only: [:create] do
    member do
      put 'accept'
      get 'received'
      put 'decline'
      get 'sent'
      get 'accepted'
    end
  end

  # Routes for invitations
  resources :invitations, only: [:index, :create, :update, :destroy] do
    post 'accept', on: :member
    post 'decline', on: :member
    post 'reschedule', on: :member
  end

  # Routes for users
  get '/users', to: 'users#index', as: 'users'
  get '/users/search', to: 'users#search'

  # Routes for tasks (alias for reminders)
  resources :tasks, only: [:index, :show, :create, :update, :destroy], controller: 'reminders'

  # Routes for notes
  resources :notes

post '/auth/send_otp',   to: 'auth/otp#send_otp'
post '/auth/verify_otp', to: 'auth/otp#verify_otp'
post '/auth/resend_otp', to: 'auth/otp#resend_otp'

  # Routes for profiles
  resources :profiles, only: [:show, :edit, :update]

  # Routes for notifications
  resources :notifications, only: [:index, :create] do
    collection do
      post 'send_notification_email' # Custom POST route for sending notification emails
    end
  end
  post 'broadcast_notification', to: 'notifications#broadcast'
end
