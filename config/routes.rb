# Rails.application.routes.draw do
#   mount_devise_token_auth_for 'User', at: 'auth', controllers: {
#     registrations: 'auth/registrations'
#   }

#   resources :reminders do
#     get 'index_by_date', on: :collection
#   end
  
#   # Define a route for handling all RESTful actions for tasks
#   resources :tasks, only: [:index, :show, :create, :update, :destroy], controller: 'reminders'

#   resources :notes
#   resources :profiles, only: [:show, :edit, :update]
#   resources :notifications, only: [:index, :create]
# end

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
    end
  end

  # Define routes for handling all RESTful actions for tasks
  resources :tasks, only: [:index, :show, :create, :update, :destroy], controller: 'reminders'

  resources :notes
  resources :profiles, only: [:show, :edit, :update]

  # Define routes for notifications
  resources :notifications, only: [:index, :create]
end
