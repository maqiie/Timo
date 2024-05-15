# Rails.application.routes.draw do
#   mount_devise_token_auth_for 'User', at: 'auth', controllers: {
#     registrations: 'auth/registrations'
#   }
#  # Custom routes for reminders
#  resources :reminders do
#   collection do
#     get 'upcoming' # Custom route to fetch upcoming reminders
#   end
# end

  
#   resources :notes
# resources :profiles, only: [:show, :edit, :update]
# resources :notifications, only: [:index, :create]




# end
Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'auth/registrations'
  }
  
  # Custom routes for reminders
  resources :reminders do
    collection do
      get 'upcoming' # Custom route to fetch upcoming reminders
    end
  end

  # Define a route for handling GET requests to "/tasks"
  resources :tasks, only: [:index] # You can adjust the actions as needed

  resources :notes
  resources :profiles, only: [:show, :edit, :update]
  resources :notifications, only: [:index, :create]
end
