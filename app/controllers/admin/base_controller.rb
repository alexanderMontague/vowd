module Admin
  class BaseController < ApplicationController
    include AdminAuthentication
    include WeddingConcern
    include AdminCanonicalHost

    layout "admin"

    before_action :require_wedding!
    before_action :require_wedding_configured!

    private

    def require_wedding_configured!
      return if skip_wedding_configured_gate?
      return if current_wedding.configured?

      redirect_to admin_website_path, alert: "Finish setting up your wedding to unlock the rest of admin."
    end

    def skip_wedding_configured_gate?
      is_a?(Admin::WebsiteController) || is_a?(Admin::Website::AssetsController)
    end
  end
end
