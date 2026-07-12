Rails.application.routes.draw do
  get "/ping", to: "application#ping"

  scope :dispo, module: :dispo do
    get "/", to: "cameras#show", as: :dispo_camera
    post "/upload", to: "cameras#create", as: :dispo_upload
    get "/gallery", to: "galleries#index", as: :dispo_gallery
  end

  get "/save-the-date", to: "public/save_the_dates#show", as: :public_save_the_date
  post "/save-the-date", to: "public/save_the_dates#signup", as: :public_save_the_date_signup
  get "/calendar.ics", to: "public/save_the_dates#calendar", as: :public_calendar_ics
  get "/faq", to: "public/faqs#show", as: :public_faq
  get "/gallery", to: "public/photos#show", as: :public_gallery
  get "/wedding-party", to: "public/wedding_parties#show", as: :public_wedding_party

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
    resource :settings, only: %i[show update]
  end

  root "public/weddings#show"
end
