module Platform
  class SessionsController < BaseController
    def new; end

    def create
      admin = AdminUser.find_by(email: params[:email].to_s.strip.downcase)

      if admin&.authenticate(params[:password])
        session[:admin_id] = admin.id
        redirect_to AppHost.wedding_admin_url(admin.wedding),
                    allow_other_host: true,
                    notice: "Logged in successfully"
      else
        flash.now[:alert] = "Invalid email or password"
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      session[:admin_id] = nil
      redirect_to platform_login_path, notice: "Logged out successfully"
    end
  end
end
