module Platform
  class PasswordResetsController < BaseController
    before_action :load_admin_from_token, only: %i[edit update]

    def new; end

    def create
      admin = AdminUser.find_by(email: params[:email].to_s.strip.downcase)
      PasswordResetMailer.reset(admin).deliver_now if admin

      redirect_to platform_login_path,
                  notice: "If that email is on file, we sent password reset instructions."
    end

    def edit; end

    def update
      if @admin.update(password_params)
        session[:admin_id] = @admin.id
        redirect_to AppHost.wedding_admin_url(@admin.wedding),
                    allow_other_host: true,
                    notice: "Password updated. You are logged in."
      else
        flash.now[:alert] = @admin.errors.full_messages.to_sentence.presence || "Could not update password"
        render :edit, status: :unprocessable_content
      end
    end

    private

    def load_admin_from_token
      @admin = AdminUser.find_by_token_for(:password_reset, params[:token])
      return if @admin

      redirect_to platform_forgot_password_path,
                  alert: "That reset link is invalid or has expired. Request a new one."
    end

    def password_params
      params.permit(:password, :password_confirmation)
    end
  end
end
