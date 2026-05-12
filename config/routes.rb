require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users,
             path: "",
             path_names: {
               sign_in: "login",
               sign_out: "logout",
               registration: "",
               sign_up: "register",
               confirmation: "verify"
             },
             controllers: {
               omniauth_callbacks: "users/omniauth_callbacks"
             }

  ActiveAdmin.routes(self)

  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.production?
    Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch("SIDEKIQ_USERNAME", "")) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("SIDEKIQ_PASSWORD", ""))
    end
  end
  mount Sidekiq::Web => "/sidekiq"

  # ─── JSON API ─────────────────────────────────────────────────────────────
  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"

      get "users/me", to: "users#me"

      resource :organisation, only: %i[show update destroy]

      resources :teams, only: %i[index show create update destroy] do
        resources :memberships, only: %i[index create destroy], controller: "teams/memberships"
      end

      resources :employees, only: %i[index show create update destroy]

      resources :invitations, only: %i[index show create destroy] do
        collection do
          post :accept
        end
      end

      resources :projects, only: %i[index show create update destroy] do
        resources :documents, only: %i[index show create update destroy], controller: "projects/documents"
        resources :remote_resources, only: %i[index show create update destroy], controller: "projects/remote_resources"
        resources :languages, only: %i[index create destroy], controller: "projects/languages"
        resources :technologies, only: %i[index create destroy], controller: "projects/technologies"
      end

      resources :languages, only: %i[index show]
      resources :technologies, only: %i[index show]
    end
  end

  # ─── Hotwire web surface ──────────────────────────────────────────────────
  root "home#show"

  get "design-system", to: "design_system#show", as: :design_system
  get "dashboard", to: "dashboard#show", as: :dashboard

  # Tenant bootstrap & ongoing organisation management.
  resources :organisations, only: %i[new create show edit update destroy]

  resources :teams do
    resources :memberships, only: %i[create destroy], controller: "teams/memberships"
  end

  resources :employees

  resources :invitations, only: %i[index new create destroy]

  # Public, token-based invitation acceptance flow (no Devise login required).
  get  "invitation_acceptances/:token", to: "invitation_acceptances#show",   as: :invitation_acceptance
  post "invitation_acceptances/:token", to: "invitation_acceptances#create", as: :submit_invitation_acceptance

  resources :projects do
    resources :documents, only: %i[index show new create edit update destroy], controller: "projects/documents"
    resources :remote_resources, only: %i[index show new create edit update destroy], controller: "projects/remote_resources"
    resources :project_languages, only: %i[create destroy], controller: "projects/languages"
    resources :project_technologies, only: %i[create destroy], controller: "projects/technologies"
  end
end
