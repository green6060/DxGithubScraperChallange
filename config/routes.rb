Rails.application.routes.draw do
  # Analytics routes
  get "analytics" => "analytics#dashboard"
  get "analytics/dashboard" => "analytics#dashboard"
  get "analytics/export" => "analytics#export"
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Simple health check that doesn't depend on external APIs
  get "health" => proc { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
  
  # Simple test route
  get "test" => proc { [200, { "Content-Type" => "text/plain" }, ["Rails is working!"]] }

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Home page with GitHub API data
  root "home#index"
end
