# Wires a wedding's chosen theme into rendering.
#
# Two things happen per request: the theme's view directory is prepended to the
# lookup path, so `app/views/themes/<key>/public/...` wins over the shared
# `app/views/public/...` templates and a theme can override only the pages it cares
# about; and the request is refused if the theme has that page switched off.
#
# Declare the page a controller serves with `guest_page :faq`. Controllers that serve
# infrastructure rather than a page (assets, search endpoints) declare nothing.
module SiteThemeRendering
  extend ActiveSupport::Concern

  included do
    include ThemePreviewing

    class_attribute :guest_page_key, instance_writer: false

    before_action :prepend_theme_view_path
    before_action :require_visible_page!

    helper_method :site_theme, :site_navigation, :theme_preview_active?
  end

  class_methods do
    def guest_page(key)
      self.guest_page_key = key.to_s
    end
  end

  private

  def site_theme
    @site_theme ||= WeddingTheme.for(current_wedding, override: theme_preview_config)
  end

  def site_navigation
    @site_navigation ||= SiteNavigation.new(
      wedding: current_wedding,
      theme: site_theme,
      preview: theme_preview_active?
    )
  end

  def prepend_theme_view_path
    return unless site_theme.views?

    prepend_view_path site_theme.view_root
  end

  def require_visible_page!
    return if guest_page_key.blank?
    return if site_navigation.visible?(guest_page_key)

    raise ActionController::RoutingError, "Not Found"
  end
end
