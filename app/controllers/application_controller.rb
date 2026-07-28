class ApplicationController < ActionController::Base
  before_action :set_session_cookie_domain

  def ping
    render plain: "Pong"
  end

  private

  def set_session_cookie_domain
    request.session_options[:domain] = AppHost.session_cookie_domain(request.host)
  end
end
