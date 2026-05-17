Rails.application.routes.draw do
  constraints subdomain: "studio" do
    mount PapyroStudio::Engine => "/", as: :papyro_studio
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions.
  get "up" => "rails/health#show", as: :rails_health_check

  # Mission Control: Jobs UI
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Design system catalog (internal tooling)
  get "design-system", to: "design_system#index", as: :design_system
  get "design-system-react", to: "design_system#react", as: :design_system_react
  get "design-system-compare", to: "design_system#compare", as: :design_system_compare

  # ActionText Markdown uploads
  namespace :action_text, path: nil do
    get "/u/*slug" => "markdown/uploads#show", as: :markdown_upload
    post "/uploads" => "markdown/uploads#create", as: :markdown_uploads
  end


  # Smart Router for root path
  root to: "root_router#route"

  localized do
    root "articles#index"

    resource :session, only: [ :new, :create, :destroy ]

    resources :passwords, only: [ :new, :create, :edit, :update ], param: :token

    resources :users, only: [ :show, :edit, :update ]

    resources :articles, only: [ :show ], param: :slug

    get "about", to: "about#index", as: :about
  end

  # Public author portfolio — non-localized vanity URL.
  get "/@:username", to: "authors#show", as: :author

  # Private settings routes — intentionally NOT localized.
  namespace :settings do
    resource :profile, only: [ :edit, :update ], controller: :profiles
    resource :security, only: [ :edit, :update ], controller: :security
  end
end
