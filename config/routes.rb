Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations'
  }

  resources :reminders do
    get 'index_by_date', on: :collection
  end
  
  # Define a route for handling all RESTful actions for tasks
  resources :tasks, only: [:index, :show, :create, :update, :destroy], controller: 'reminders'

  resources :notes
  resources :profiles, only: [:show, :edit, :update]
  resources :notifications, only: [:index, :create]
end

# Rails.application.routes.draw do
#   mount_devise_token_auth_for 'User', at: 'auth', controllers: {
#     registrations: 'auth/registrations'
#   }

#   resources :reminders, only: [:show, :index, :create, :update, :destroy]
#   get 'tasks/by_date/:date', to: 'reminders#index_by_date', as: 'tasks_by_date'

  
#   # Custom routes for reminders
#   resources :reminders do
#     collection do
#       get 'upcoming' # Custom route to fetch upcoming reminders
#     end
#   end

#   # Define a route for handling GET requests to "/tasks"
#   resources :tasks, only: [:index] # You can adjust the actions as needed

#   resources :notes
#   resources :profiles, only: [:show, :edit, :update]
#   resources :notifications, only: [:index, :create]
# end
