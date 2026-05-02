require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users,
             path: "",
             controllers: { registrations: "users/registrations" },
             path_names: {
               sign_in: "login",
               sign_out: "logout",
               registration: "",
               sign_up: "register"
             }

  ActiveAdmin.routes(self)

  # Healthcheck for load balancers / Render.
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq dashboard. Locked behind HTTP basic auth in production via env vars.
  if Rails.env.production?
    Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch("SIDEKIQ_USERNAME", "")) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("SIDEKIQ_PASSWORD", ""))
    end
  end
  mount Sidekiq::Web => "/sidekiq"

  # Hotwire web surface goes here as features land.
  # API surface for future mobile / 3rd-party clients.
  namespace :api do
    namespace :v1 do
      # endpoints will be added in later phases
    end
  end

  root "home#show"

  get "design-system", to: "design_system#show", as: :design_system
  get "dashboard", to: "dashboard#show", as: :dashboard
end
