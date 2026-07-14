module WeddingConcern
  extend ActiveSupport::Concern

  included do
    helper_method :current_wedding
  end

  private

  def current_wedding
    @current_wedding ||= TenantResolver.call(host: request.host)
  end

  def require_wedding!
    return if current_wedding

    raise ActionController::RoutingError, "Not Found"
  end
end
