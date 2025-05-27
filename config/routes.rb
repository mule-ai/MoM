Rails.application.routes.draw do
  # Web interface
  root "home#index"
  get "/health", to: "application#health"
  post "/debug/heartbeat", to: "home#trigger_heartbeat"
  
  resources :mule_clients, path: "clients", param: :id do
    member do
      post :execute_workflow
      get :status
    end
  end
  
  # API endpoints
  namespace :api do
    namespace :v1 do
      resources :mule_clients, only: [:index, :show, :create, :destroy] do
        member do
          post :execute_workflow
          get :status
        end
      end
      
      resources :workflows, only: [:index, :show, :create] do
        member do
          post :execute
        end
      end
    end
  end
end