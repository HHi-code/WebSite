Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"

  # Catalog routes
  resources :catalogs, only: [:create, :show] do
    resources :elements, only: [:create, :show]
  end

  # TierLists
  resources :tier_lists, only: [:index, :create, :show] do
    # Сохранение распределения элементов по рангам редактора
    resource :layout, only: [:update], controller: "tier_list_layouts"
    # Создание, удаление и импорт элементов напрямую внутри тирлиста
    resources :elements, only: [:create, :destroy], controller: "tier_list_elements" do
      post :import, on: :collection
    end
  end

  # Styleguide
  get "/styleguide", to: "pages#styleguide"

  # Authentication routes
  get  "/signup", to: "registrations#new"
  post "/signup", to: "registrations#create"
  get  "/login",  to: "sessions#new"
  post "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
end
