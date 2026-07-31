module Admin
  class BaseController < ApplicationController
    include AdminAuthentication
    include WeddingConcern
    include AdminCanonicalHost
    include SiteEditor
    include BillingGate

    layout "admin"

    before_action :require_wedding!
    before_action :require_wedding_configured!
    before_action :clear_site_editor_outside_theme!

    private

    def require_wedding_configured!
      return if skip_wedding_configured_gate?
      return if current_wedding.configured?

      redirect_to admin_website_path, alert: "Finish setting up your wedding to unlock the rest of admin."
    end

    def skip_wedding_configured_gate?
      is_a?(Admin::WebsiteController) ||
        is_a?(Admin::Website::AssetsController) ||
        is_a?(Admin::BillingController)
    end

    def clear_site_editor_outside_theme!
      return if is_a?(Admin::ThemesController) || is_a?(Admin::Themes::PreviewsController)
      return if is_a?(Admin::Website::AssetsController)

      clear_site_editor!
    end
  end
end
