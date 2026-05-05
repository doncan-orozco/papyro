Rails.application.routes.draw do
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

  # Non-localized homepage.
  # LocaleManagement will choose locale from params, session, browser, or default.
  get "/", to: "articles#index"

  localized do
    root "articles#index"

    resource :session, only: [ :new, :create, :destroy ]
    resources :passwords, only: [ :new, :create, :edit, :update ], param: :token

    resources :users, only: [ :show, :edit, :update ]

    resources :articles, only: [ :index, :show ], param: :slug

    get "about", to: "about#index", as: :about
  end

  # Private settings routes — intentionally NOT localized.
  namespace :settings do
    resource :profile, only: [ :edit, :update ], controller: :profiles
    resource :security, only: [ :edit, :update ], controller: :security
  end

  # Private studio routes — intentionally NOT localized.
  # URL stays /studio/... regardless of I18n.locale; UI language is set via I18n.
  namespace :studio do
    resources :articles, only: [ :index, :create, :edit, :update, :destroy ], param: :uuid do
      member do
        patch :restore
        delete :purge
      end

      resource :publication, only: [ :new, :create, :destroy ], controller: :publications
    end
  end
end
