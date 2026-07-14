module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
    helper_method :current_admin, :admin_logged_in?
  end

  private

  def require_admin
    unless current_admin
      redirect_to admin_login_path, alert: "Please log in to continue"
      return
    end

    return unless current_wedding
    return if current_admin.wedding_id == current_wedding.id

    session[:admin_id] = nil
    redirect_to admin_login_path, alert: "You do not have access to this wedding"
  end

  def current_admin
    @current_admin ||= AdminUser.find_by(id: session[:admin_id]) if session[:admin_id]
  end

  def admin_logged_in?
    current_admin.present?
  end
end
