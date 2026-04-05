Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Mission Control: Jobs UI
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Home (landing page)
  root "home#index"

  # Public authentication (for future public users if needed)
  resource :session, only: [ :new, :create, :destroy ]
  resources :passwords, only: [ :new, :create, :edit, :update ], param: :token

  # Admin namespace - requires authentication
  namespace :admin do
    resource :session, only: [ :new, :create, :destroy ]

    # Articles CRUD + publish action
    resources :articles do
      member do
        patch :publish
      end
    end

    # Admin root will be articles index
    root "articles#index"
  end

  # Admin login shortcuts
  get "/admin/login", to: "admin/sessions#new", as: :admin_login
  delete "/admin/logout", to: "admin/sessions#destroy", as: :admin_logout

  # Design system catalog (Phlex components)
  get "design-system", to: "design_system#index", as: :design_system

  # React shadcn catalog (reference)
  get "design-system-react", to: "design_system#react", as: :design_system_react

  # Split-screen comparison (React vs Phlex)
  get "design-system-compare", to: "design_system#compare", as: :design_system_compare

  # Public articles (by slug, no auth required)
  resources :articles, only: [ :index, :show ], param: :slug do
    collection do
      get :featured
    end
  end

  # ActionText Markdown uploads
  namespace :action_text, path: nil do
    get "/u/*slug" => "markdown/uploads#show", as: :markdown_upload
    post "/admin/uploads" => "markdown/uploads#create", as: :markdown_uploads
  end
end
