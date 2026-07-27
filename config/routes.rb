Rails.application.routes.draw do
  get "/ping", to: "application#ping"

  constraints PlatformHostConstraint do
    root "platform/homes#show", as: :platform_root

    get "/signup", to: "platform/registrations#new", as: :platform_signup
    post "/signup", to: "platform/registrations#create"
    get "/login", to: "platform/sessions#new", as: :platform_login
    post "/login", to: "platform/sessions#create"
    delete "/logout", to: "platform/sessions#destroy", as: :platform_logout
  end

  constraints WeddingHostConstraint do
    scope :dispo, module: :dispo do
      get "/", to: "cameras#show", as: :dispo_camera
      post "/upload", to: "cameras#create", as: :dispo_upload
      get "/gallery", to: "galleries#index", as: :dispo_gallery
      get "/gallery/:id/raw", to: "galleries#raw", as: :dispo_photo_raw
    end

    get "/save-the-date", to: "public/save_the_dates#show", as: :public_save_the_date
    post "/save-the-date", to: "public/save_the_dates#signup", as: :public_save_the_date_signup
    get "/calendar.ics", to: "public/save_the_dates#calendar", as: :public_calendar_ics
    get "/faq", to: "public/faqs#show", as: :public_faq
    get "/photos", to: "public/photos#show", as: :public_photos
    get "/gallery", to: redirect("/photos")
    get "/wedding-party", to: "public/wedding_parties#show", as: :public_wedding_party
    get "/site-assets/*object_key", to: "public/site_assets#show", as: :public_site_asset, format: false

    get "/rsvp", to: "public/rsvps#index", as: :public_rsvp_lookup
    get "/rsvp/search", to: "public/rsvps#search", as: :public_rsvp_search
    get "/rsvp/:code", to: "public/rsvps#edit", as: :public_rsvp
    patch "/rsvp/:code", to: "public/rsvps#update"
    get "/rsvp/:code/thanks", to: "public/rsvps#thanks", as: :public_rsvp_thanks

    namespace :admin do
      get "/login", to: "sessions#new", as: :login
      post "/login", to: "sessions#create"
      delete "/logout", to: "sessions#destroy", as: :logout

      root "dashboard#index"

      resources :events
      resources :guests do
        collection do
          get :export
        end
      end
      resources :households
      resources :save_the_date_signups, only: %i[index destroy] do
        member do
          patch :match
          delete :unmatch
        end
      end
      resources :invitations, only: %i[index create] do
        collection do
          get :physical
        end
      end
      resources :disposable_photos, only: :index do
        collection do
          delete :destroy_selected
          delete :destroy_all
        end
      end
      resource :dispo_sign, only: :show, controller: "dispo_signs"
      resource :settings, only: %i[show update]

      get "theme", to: "themes#show"
      # Preview must be declared before :section or PATCH /theme/preview is stolen.
      resource :theme, only: [], controller: "themes" do
        resource :preview, only: %i[create update destroy], module: :themes, controller: "previews"
      end
      scope path: "theme", as: "theme", controller: "themes" do
        get ":section", action: :show, as: :section, constraints: { section: ThemeSections.constraint }
        patch ":section", action: :update
      end

      get "website", to: "website#show"
      patch "website", to: "website#update"
      scope path: "website", as: "website", controller: "website" do
        get ":section", action: :show, as: :section, constraints: { section: WebsiteSections.constraint }
        patch ":section", action: :update
        resources :assets, only: %i[create update destroy], module: :website do
          collection do
            delete :destroy_selected
          end
        end
      end
    end

    root "public/weddings#show"
  end
end
