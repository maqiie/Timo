
Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations'
  }

  resources :reminders do
    collection do
      get 'index_by_date'
    end

    member do
      patch 'complete'
      patch 'update' # Adding the route to update a reminder (task)
      get :special_events

    end
  end
  


  resources :tasks, only: [:index, :show, :create, :update, :destroy], controller: 'reminders'
  resources :notes
  resources :profiles, only: [:show, :edit, :update]

  resources :notifications, only: [:index, :create] do
    collection do
      post 'send_notification_email' # Define a custom POST route for sending notification emails
    end
  end
  
end
