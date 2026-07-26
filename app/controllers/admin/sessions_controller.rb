module Admin
  class SessionsController < ApplicationController
    include WeddingConcern
    include AdminCanonicalHost

    layout "admin_auth"

    before_action :require_wedding!
    before_action :redirect_if_logged_in, only: %i[new create]

    def new; end

    def create
      admin = AdminUser.find_by(email: params[:email].to_s.strip.downcase)

      if admin&.authenticate(params[:password]) && admin.wedding_id == current_wedding.id
        session[:admin_id] = admin.id
        destination = admin.wedding.configured? ? admin_root_path : admin_website_path
        redirect_to destination, notice: "Logged in successfully"
      else
        flash.now[:alert] = "Invalid email or password"
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      session[:admin_id] = nil
      redirect_to admin_login_path, notice: "Logged out successfully"
    end

    private

    def redirect_if_logged_in
      return unless session[:admin_id].present?

      admin = AdminUser.find_by(id: session[:admin_id])
      return unless admin&.wedding_id == current_wedding.id

      destination = admin.wedding.configured? ? admin_root_path : admin_website_path
      redirect_to destination
    end
  end
end
