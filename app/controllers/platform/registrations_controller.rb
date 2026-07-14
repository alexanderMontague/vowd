module Platform
  class RegistrationsController < BaseController
    def new
      @registration = registration_defaults
    end

    def create
      result = WeddingRegistration.call(**registration_params.to_h.symbolize_keys)

      if result[:success]
        session[:admin_id] = result[:admin_user].id
        redirect_to AppHost.wedding_admin_url(result[:wedding], path: "/admin/website"),
                    allow_other_host: true,
                    notice: "Welcome to Vowd! Set up your wedding to get started."
      else
        @registration = registration_params.to_h
        flash.now[:alert] = result[:errors].to_sentence.presence || "Could not create your account"
        render :new, status: :unprocessable_content
      end
    end

    private

    def registration_params
      params.permit(
        :email,
        :password,
        :password_confirmation,
        :slug,
        :title,
        :partner1,
        :partner2
      )
    end

    def registration_defaults
      {
        "email" => nil,
        "slug" => nil,
        "title" => nil,
        "partner1" => nil,
        "partner2" => nil
      }
    end
  end
end
